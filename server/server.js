'use strict';
/**
 * The Capture the Base game server: one small Node program that does everything online.
 *
 * - Serves the web game from public/ (the same address players open in a browser).
 * - HTTP API: accounts, cloud saves, leaderboards, guilds.
 * - WebSocket /ws: chat, matchmaking, Friend Rooms, and passing match data between players.
 *
 * Matches run on one player's device (the host) with the same rules code as a practice match; the server
 * passes snapshots and inputs along. If the host drops, it names another player as host, who carries on
 * from the last snapshot. Empty seats go to AI, played by the host.
 *
 * Settings come from the environment: PORT (8787), DB_PATH (data/game.db), PUBLIC_DIR (public),
 * QUEUE_WAIT_SECONDS (10). Needs Node 22.13 or newer, for the built-in SQLite.
 */

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = Number(process.env.PORT || 8787);
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data', 'game.db');
const PUBLIC_DIR = path.resolve(process.env.PUBLIC_DIR || path.join(__dirname, 'public'));
const QUEUE_WAIT = Number(process.env.QUEUE_WAIT_SECONDS || 10);

const TEAM_SIZE = 5;
const SEATS = TEAM_SIZE * 2;
const GUILD_MAX = 30;
const MAX_JSON = 128 * 1024;
const MAX_SAVE = 64 * 1024;
const CHAT_HISTORY = 50;
const RESULT_WAIT_MS = 6000;
const LOGIN_LIMIT = 20; // Attempts per IP per 10 minutes.
const GUEST_LIMIT = 60; // New guests per IP per hour.
const BAD_WORDS = ['fuck', 'shit', 'bitch', 'asshole', 'cunt', 'nigger', 'faggot', 'putangina', 'tangina', 'gago', 'tarantado', 'puta', 'kantot', 'pakyu'];

// --- Database ------------------------------------------------------------------------------------

fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
const db = new DatabaseSync(DB_PATH);
db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA foreign_keys = ON;
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE COLLATE NOCASE,
    pass_hash TEXT,
    display_name TEXT NOT NULL,
    trophies INTEGER NOT NULL DEFAULT 0,
    best_trophies INTEGER NOT NULL DEFAULT 0,
    wins INTEGER NOT NULL DEFAULT 0,
    games INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    guild_id INTEGER,
    look TEXT NOT NULL DEFAULT '{}',
    save TEXT,
    created_at INTEGER NOT NULL,
    last_seen INTEGER NOT NULL
  );
  CREATE INDEX IF NOT EXISTS users_trophies ON users (trophies DESC);
  CREATE INDEX IF NOT EXISTS users_guild ON users (guild_id);
  CREATE TABLE IF NOT EXISTS tokens (
    token_hash TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL
  );
  CREATE TABLE IF NOT EXISTS guilds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE COLLATE NOCASE,
    tag TEXT NOT NULL,
    about TEXT NOT NULL DEFAULT '',
    badge INTEGER NOT NULL DEFAULT 0,
    leader_id INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  );
  CREATE TABLE IF NOT EXISTS chat (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    channel TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    guild TEXT NOT NULL DEFAULT '',
    trophies INTEGER NOT NULL DEFAULT 0,
    text TEXT NOT NULL,
    at INTEGER NOT NULL
  );
  CREATE INDEX IF NOT EXISTS chat_channel ON chat (channel, id DESC);
`);

const q = {
  userById: db.prepare('SELECT * FROM users WHERE id = ?'),
  userByName: db.prepare('SELECT * FROM users WHERE username = ?'),
  userByToken: db.prepare('SELECT u.* FROM tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = ?'),
  addUser: db.prepare('INSERT INTO users (display_name, look, save, created_at, last_seen) VALUES (?, ?, ?, ?, ?)'),
  addToken: db.prepare('INSERT INTO tokens (token_hash, user_id, created_at) VALUES (?, ?, ?)'),
  dropToken: db.prepare('DELETE FROM tokens WHERE token_hash = ?'),
  setProfile: db.prepare('UPDATE users SET display_name = ?, look = ?, level = ?, save = ?, last_seen = ? WHERE id = ?'),
  setCreds: db.prepare('UPDATE users SET username = ?, pass_hash = ? WHERE id = ?'),
  setResult: db.prepare('UPDATE users SET trophies = ?, best_trophies = ?, wins = wins + ?, games = games + 1, last_seen = ? WHERE id = ?'),
  topPlayers: db.prepare(`SELECT u.id, u.display_name AS name, u.trophies, u.level, u.look, COALESCE(g.tag, '') AS guild
    FROM users u LEFT JOIN guilds g ON g.id = u.guild_id ORDER BY u.trophies DESC, u.id ASC LIMIT ?`),
  playerRank: db.prepare('SELECT COUNT(*) AS above FROM users WHERE trophies > ?'),
  topGuilds: db.prepare(`SELECT g.id, g.name, g.tag, g.badge, SUM(u.trophies) AS trophies, COUNT(u.id) AS members
    FROM guilds g JOIN users u ON u.guild_id = g.id GROUP BY g.id ORDER BY trophies DESC, g.id ASC LIMIT ?`),
  searchGuilds: db.prepare(`SELECT g.id, g.name, g.tag, g.about, g.badge, COALESCE(SUM(u.trophies), 0) AS trophies, COUNT(u.id) AS members
    FROM guilds g LEFT JOIN users u ON u.guild_id = g.id WHERE g.name LIKE ? OR g.tag LIKE ?
    GROUP BY g.id ORDER BY trophies DESC LIMIT 50`),
  guild: db.prepare('SELECT * FROM guilds WHERE id = ?'),
  guildMembers: db.prepare('SELECT id, display_name AS name, trophies, level FROM users WHERE guild_id = ? ORDER BY trophies DESC'),
  guildCount: db.prepare('SELECT COUNT(*) AS n FROM users WHERE guild_id = ?'),
  addGuild: db.prepare('INSERT INTO guilds (name, tag, about, badge, leader_id, created_at) VALUES (?, ?, ?, ?, ?, ?)'),
  setGuild: db.prepare('UPDATE users SET guild_id = ? WHERE id = ?'),
  setLeader: db.prepare('UPDATE guilds SET leader_id = ? WHERE id = ?'),
  dropGuild: db.prepare('DELETE FROM guilds WHERE id = ?'),
  addChat: db.prepare('INSERT INTO chat (channel, user_id, name, guild, trophies, text, at) VALUES (?, ?, ?, ?, ?, ?, ?)'),
  chatHistory: db.prepare('SELECT name, guild, trophies, text, at FROM chat WHERE channel = ? ORDER BY id DESC LIMIT ?'),
  trimChat: db.prepare('DELETE FROM chat WHERE channel = ? AND id < (SELECT MIN(id) FROM (SELECT id FROM chat WHERE channel = ? ORDER BY id DESC LIMIT 200))'),
};

const now = () => Math.floor(Date.now() / 1000);
const sha = (text) => crypto.createHash('sha256').update(text).digest('hex');

function newToken(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  q.addToken.run(sha(token), userId, now());
  return token;
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(password, salt, 32);
  return `${salt.toString('hex')}:${hash.toString('hex')}`;
}

function checkPassword(password, stored) {
  if (!stored) return false;
  const [salt, hash] = stored.split(':');
  const got = crypto.scryptSync(password, Buffer.from(salt, 'hex'), 32);
  const want = Buffer.from(hash, 'hex');
  return got.length === want.length && crypto.timingSafeEqual(got, want);
}

function cleanName(text, maxLength = 16) {
  return String(text ?? '').replace(/[\u0000-\u001f\u007f]/g, '').trim().slice(0, maxLength);
}

function isRude(text) {
  const plain = String(text).toLowerCase().replace(/[^a-z]/g, '');
  return BAD_WORDS.some((word) => plain.includes(word));
}

function maskRude(text) {
  let out = String(text);
  for (const word of BAD_WORDS) {
    out = out.replace(new RegExp(word, 'gi'), '*'.repeat(word.length));
  }
  return out;
}

function publicUser(row) {
  let guildName = '';
  if (row.guild_id) {
    const guild = q.guild.get(row.guild_id);
    guildName = guild ? guild.name : '';
  }
  let save = null;
  try {
    save = row.save ? JSON.parse(row.save) : null;
  } catch {
    save = null;
  }
  return {
    id: row.id, username: row.username || '', display_name: row.display_name, trophies: row.trophies,
    best_trophies: row.best_trophies, wins: row.wins, games: row.games, level: row.level,
    guild_id: row.guild_id || 0, guild_name: guildName, save,
  };
}

// --- Rate limits ---------------------------------------------------------------------------------

const limits = new Map();
function overLimit(key, max, windowSeconds) {
  const t = now();
  const entry = limits.get(key);
  if (!entry || entry.until < t) {
    limits.set(key, { count: 1, until: t + windowSeconds });
    return false;
  }
  entry.count += 1;
  return entry.count > max;
}
setInterval(() => {
  const t = now();
  for (const [key, entry] of limits) if (entry.until < t) limits.delete(key);
}, 60000).unref();

// --- HTTP API ------------------------------------------------------------------------------------

class ApiError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function clientIp(req) {
  const edge = req.headers['cf-connecting-ip'];
  if (typeof edge === 'string' && edge) return edge;
  const forwarded = req.headers['x-forwarded-for'];
  return (typeof forwarded === 'string' && forwarded.split(',')[0].trim()) || req.socket.remoteAddress || '?';
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_JSON) {
        reject(new ApiError(413, 'Too much data.'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      if (size === 0) return resolve({});
      try {
        const value = JSON.parse(Buffer.concat(chunks).toString('utf8'));
        resolve(value && typeof value === 'object' ? value : {});
      } catch {
        reject(new ApiError(400, 'That request made no sense.'));
      }
    });
    req.on('error', reject);
  });
}

function authUser(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  return q.userByToken.get(sha(header.slice(7))) || null;
}

function requireUser(req) {
  const user = authUser(req);
  if (!user) throw new ApiError(401, 'Please sign in again.');
  return user;
}

function saveText(save) {
  if (!save || typeof save !== 'object') return null;
  const text = JSON.stringify(save);
  return text.length <= MAX_SAVE ? text : null;
}

const routes = {
  'GET /api/health': async () => ({ ok: true, online: clients.size }),

  'POST /api/auth/guest': async (req, body) => {
    if (overLimit(`guest:${clientIp(req)}`, GUEST_LIMIT, 3600)) throw new ApiError(429, 'Too many new players from here. Try again later.');
    let name = cleanName(body.name) || `Runner${crypto.randomInt(100, 999)}`;
    if (isRude(name)) name = `Runner${crypto.randomInt(100, 999)}`;
    const t = now();
    const info = q.addUser.run(name, '{}', saveText(body.save), t, t);
    const id = Number(info.lastInsertRowid);
    return { token: newToken(id), user: publicUser(q.userById.get(id)) };
  },

  'POST /api/auth/register': async (req, body) => {
    const user = requireUser(req);
    const username = cleanName(body.username, 20);
    const password = String(body.password ?? '');
    if (!/^[A-Za-z0-9_.-]{3,20}$/.test(username)) throw new ApiError(400, 'Usernames are 3-20 letters, numbers, dots or dashes.');
    if (isRude(username)) throw new ApiError(400, "Let's pick a friendlier username.");
    if (password.length < 8 || password.length > 64) throw new ApiError(400, 'Passwords are 8-64 characters.');
    if (user.username) throw new ApiError(400, 'This player already has an account.');
    if (q.userByName.get(username)) throw new ApiError(409, 'That username is taken.');
    q.setCreds.run(username, hashPassword(password), user.id);
    return { user: publicUser(q.userById.get(user.id)) };
  },

  'POST /api/auth/login': async (req, body) => {
    if (overLimit(`login:${clientIp(req)}`, LOGIN_LIMIT, 600)) throw new ApiError(429, 'Too many tries. Wait a few minutes.');
    const user = q.userByName.get(cleanName(body.username, 20));
    if (!user || !checkPassword(String(body.password ?? ''), user.pass_hash)) throw new ApiError(401, 'Wrong username or password.');
    return { token: newToken(user.id), user: publicUser(user) };
  },

  'POST /api/auth/logout': async (req) => {
    const header = req.headers.authorization || '';
    if (header.startsWith('Bearer ')) q.dropToken.run(sha(header.slice(7)));
    return { ok: true };
  },

  'GET /api/me': async (req) => ({ user: publicUser(requireUser(req)) }),

  'PUT /api/me': async (req, body) => {
    const user = requireUser(req);
    let name = cleanName(body.name) || user.display_name;
    if (name.length < 3 || isRude(name)) name = user.display_name;
    const look = body.look && typeof body.look === 'object' ? JSON.stringify(body.look).slice(0, 2000) : user.look;
    const level = Math.max(1, Math.min(Number(body.level) || user.level, 9999));
    q.setProfile.run(name, look, level, saveText(body.save) ?? user.save, now(), user.id);
    return { ok: true, display_name: name };
  },

  'GET /api/leaderboard': async (req, _body, url) => {
    const limit = Math.max(1, Math.min(Number(url.searchParams.get('limit')) || 100, 100));
    const me = authUser(req);
    if (url.searchParams.get('scope') === 'guilds') {
      return { rows: q.topGuilds.all(limit) };
    }
    const rows = q.topPlayers.all(limit).map((row) => ({ name: row.name, trophies: row.trophies, level: row.level, guild: row.guild }));
    const out = { rows };
    if (me) {
      out.me = { rank: q.playerRank.get(me.trophies).above + 1, name: me.display_name, trophies: me.trophies, guild: '' };
    }
    return out;
  },

  'GET /api/guilds': async (_req, _body, url) => {
    const search = `%${String(url.searchParams.get('q') || '').replace(/[%_]/g, '').slice(0, 24)}%`;
    return { guilds: q.searchGuilds.all(search, search).map((g) => ({ ...g, max: GUILD_MAX })) };
  },

  'POST /api/guilds': async (req, body) => {
    const user = requireUser(req);
    if (user.guild_id) throw new ApiError(400, 'Leave your guild first.');
    const name = cleanName(body.name, 20);
    const tag = cleanName(body.tag, 4).toUpperCase();
    const about = maskRude(cleanName(body.about, 80));
    if (name.length < 3 || isRude(name)) throw new ApiError(400, 'Pick a friendly guild name of 3-20 letters.');
    if (!/^[A-Z0-9]{2,4}$/.test(tag) || isRude(tag)) throw new ApiError(400, 'Tags are 2-4 letters or numbers.');
    let info;
    try {
      info = q.addGuild.run(name, tag, about, Math.max(0, Math.min(Number(body.badge) || 0, 7)), user.id, now());
    } catch {
      throw new ApiError(409, 'That guild name is taken.');
    }
    const id = Number(info.lastInsertRowid);
    q.setGuild.run(id, user.id);
    syncClientGuild(user.id, id);
    return { guild: q.guild.get(id) };
  },

  'POST /api/guilds/leave': async (req) => {
    const user = requireUser(req);
    if (user.guild_id) leaveGuild(user);
    return { ok: true };
  },

  'POST /api/guilds/kick': async (req, body) => {
    const user = requireUser(req);
    const guild = user.guild_id ? q.guild.get(user.guild_id) : null;
    if (!guild || guild.leader_id !== user.id) throw new ApiError(403, 'Only the guild leader can do that.');
    const target = q.userById.get(Number(body.user_id) || 0);
    if (!target || target.guild_id !== guild.id || target.id === user.id) throw new ApiError(400, "That player isn't in your guild.");
    q.setGuild.run(null, target.id);
    syncClientGuild(target.id, 0);
    notifyGuild(guild.id);
    return { ok: true };
  },
};

function leaveGuild(user) {
  const guildId = user.guild_id;
  q.setGuild.run(null, user.id);
  syncClientGuild(user.id, 0);
  const guild = q.guild.get(guildId);
  if (!guild) return;
  const rest = q.guildMembers.all(guildId);
  if (rest.length === 0) {
    q.dropGuild.run(guildId);
  } else {
    if (guild.leader_id === user.id) q.setLeader.run(rest[0].id, guildId); // The top player takes over.
    notifyGuild(guildId);
  }
}

async function handleApi(req, res, url) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Cache-Control', 'no-store');
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  try {
    let route = routes[`${req.method} ${url.pathname}`];
    let params = null;
    const guildMatch = url.pathname.match(/^\/api\/guilds\/(\d+)(\/join)?$/);
    if (!route && guildMatch) {
      params = Number(guildMatch[1]);
      if (req.method === 'GET' && !guildMatch[2]) route = guildPage;
      else if (req.method === 'POST' && guildMatch[2]) route = guildJoin;
    }
    if (!route) throw new ApiError(404, 'Not found.');
    const body = req.method === 'POST' || req.method === 'PUT' ? await readJson(req) : {};
    const data = await route(req, body, url, params);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  } catch (error) {
    const code = error instanceof ApiError ? error.code : 500;
    if (code === 500) console.error('API error', url.pathname, error);
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: code === 500 ? 'Something went wrong.' : error.message }));
  }
}

async function guildPage(req, _body, _url, id) {
  const guild = q.guild.get(id);
  if (!guild) throw new ApiError(404, 'That guild is gone.');
  const members = q.guildMembers.all(id);
  const me = authUser(req);
  const trophies = members.reduce((sum, m) => sum + m.trophies, 0);
  return { guild: { ...guild, trophies }, members, me_id: me ? me.id : 0 };
}

async function guildJoin(req, _body, _url, id) {
  const user = requireUser(req);
  if (user.guild_id) throw new ApiError(400, 'Leave your guild first.');
  const guild = q.guild.get(id);
  if (!guild) throw new ApiError(404, 'That guild is gone.');
  if (q.guildCount.get(id).n >= GUILD_MAX) throw new ApiError(409, 'That guild is full.');
  q.setGuild.run(id, user.id);
  syncClientGuild(user.id, id);
  notifyGuild(id);
  return { guild };
}

// --- The web game --------------------------------------------------------------------------------

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon', '.json': 'application/json', '.webmanifest': 'application/manifest+json',
};

function serveStatic(req, res, url) {
  let relative = decodeURIComponent(url.pathname);
  if (relative === '/') relative = '/index.html';
  const file = path.resolve(PUBLIC_DIR, `.${relative}`);
  if (file !== PUBLIC_DIR && !file.startsWith(PUBLIC_DIR + path.sep)) {
    res.writeHead(403);
    res.end();
    return;
  }
  const accepts = String(req.headers['accept-encoding'] || '');
  const gz = `${file}.gz`;
  const hasPlain = fs.existsSync(file) && fs.statSync(file).isFile();
  const hasGz = fs.existsSync(gz);
  if (!hasPlain && !hasGz) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not found. Has the web game been exported? See the README.');
    return;
  }
  const ext = path.extname(file);
  const headers = {
    'Content-Type': MIME[ext] || 'application/octet-stream',
    // The page always revalidates; the big files are renamed by nothing, so they revalidate too.
    'Cache-Control': 'no-cache',
    'X-Content-Type-Options': 'nosniff',
  };
  const source = hasGz ? gz : file;
  const stat = fs.statSync(source);
  const etag = `"${stat.size.toString(16)}-${Math.floor(stat.mtimeMs).toString(16)}"`;
  headers.ETag = etag;
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, headers);
    res.end();
    return;
  }
  if (hasGz && accepts.includes('gzip')) {
    headers['Content-Encoding'] = 'gzip';
    headers['Content-Length'] = stat.size;
    res.writeHead(200, headers);
    fs.createReadStream(gz).pipe(res);
  } else if (hasGz) {
    res.writeHead(200, headers);
    fs.createReadStream(gz).pipe(zlib.createGunzip()).pipe(res);
  } else {
    headers['Content-Length'] = stat.size;
    res.writeHead(200, headers);
    fs.createReadStream(file).pipe(res);
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname.startsWith('/api/')) {
    handleApi(req, res, url);
  } else if (req.method === 'GET' || req.method === 'HEAD') {
    serveStatic(req, res, url);
  } else {
    res.writeHead(405);
    res.end();
  }
});

// --- Realtime ------------------------------------------------------------------------------------

const clients = new Map(); // userId -> client
const queue = [];
const matches = new Map();
const rooms = new Map();
const wss = new WebSocketServer({ server, path: '/ws', maxPayload: 64 * 1024 });

function send(client, data) {
  if (client && client.ws.readyState === WebSocket.OPEN) client.ws.send(JSON.stringify(data));
}

function broadcast(data) {
  const text = JSON.stringify(data);
  for (const client of clients.values()) {
    if (client.ws.readyState === WebSocket.OPEN) client.ws.send(text);
  }
}

function syncClientGuild(userId, guildId) {
  const client = clients.get(userId);
  if (client) {
    client.guildId = guildId;
    const guild = guildId ? q.guild.get(guildId) : null;
    client.guildTag = guild ? guild.tag : '';
  }
}

function notifyGuild(guildId) {
  for (const client of clients.values()) {
    if (client.guildId === guildId) send(client, { t: 'guild_update' });
  }
}

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, 'http://localhost');
  const row = q.userByToken.get(sha(url.searchParams.get('token') || ''));
  if (!row) {
    ws.close(4001, 'Please sign in again.');
    return;
  }
  const old = clients.get(row.id);
  if (old) {
    // A second tab or device takes over this account's connection.
    old.replaced = true;
    onDisconnect(old);
    old.ws.close(4002, 'Signed in somewhere else.');
  }
  const guild = row.guild_id ? q.guild.get(row.guild_id) : null;
  const client = {
    ws, id: row.id, name: row.display_name, trophies: row.trophies,
    guildId: row.guild_id || 0, guildTag: guild ? guild.tag : '',
    chatAt: 0, chatBurst: 0, match: null, seat: -1, room: null, look: {}, alive: true,
  };
  clients.set(row.id, client);
  ws.on('pong', () => { client.alive = true; });
  ws.on('message', (data, isBinary) => {
    try {
      if (isBinary) onBinary(client, data);
      else onText(client, data.toString('utf8'));
    } catch (error) {
      console.error('Message error', error);
    }
  });
  ws.on('close', () => {
    if (!client.replaced) onDisconnect(client);
  });
  send(client, { t: 'online', count: clients.size });
});

function onDisconnect(client) {
  if (clients.get(client.id) === client) clients.delete(client.id);
  leaveQueue(client);
  leaveRoom(client);
  leaveMatch(client);
}

function onText(client, text) {
  let msg;
  try {
    msg = JSON.parse(text);
  } catch {
    return;
  }
  switch (msg.t) {
    case 'ping': send(client, { t: 'online', count: clients.size }); break;
    case 'chat': onChat(client, msg); break;
    case 'chat_history': sendHistory(client, msg.channel); break;
    case 'subscribe_guild': {
      const row = q.userById.get(client.id);
      syncClientGuild(client.id, row ? row.guild_id || 0 : 0);
      break;
    }
    case 'queue': joinQueue(client, msg); break;
    case 'queue_leave': leaveQueue(client); break;
    case 'room_create': roomCreate(client, msg); break;
    case 'room_join': roomJoin(client, msg); break;
    case 'room_leave': leaveRoom(client); break;
    case 'room_team': roomTeam(client, msg); break;
    case 'room_config': roomConfig(client, msg); break;
    case 'room_start': roomStart(client); break;
    case 'match_emote': onMatchEmote(client, msg); break;
    case 'match_end': onMatchEnd(client, msg); break;
    case 'match_leave': leaveMatch(client); break;
    default: break;
  }
}

// --- Chat ----------------------------------------------------------------------------------------

function channelKey(client, channel) {
  if (channel === 'guild') return client.guildId ? `guild:${client.guildId}` : null;
  return channel === 'global' ? 'global' : null;
}

function sendHistory(client, channel) {
  const key = channelKey(client, channel);
  if (!key) return;
  const messages = q.chatHistory.all(key, CHAT_HISTORY).reverse();
  send(client, { t: 'chat_history', channel, messages });
}

function onChat(client, msg) {
  const key = channelKey(client, msg.channel);
  if (!key) return;
  const text = maskRude(cleanName(msg.text, 140));
  if (!text) return;
  const t = Date.now();
  // A burst of four, then one message every 1.5 seconds.
  client.chatBurst = Math.max(0, client.chatBurst - (t - client.chatAt) / 1500);
  if (client.chatBurst >= 4) return;
  client.chatBurst += 1;
  client.chatAt = t;
  const row = q.userById.get(client.id);
  const message = {
    t: 'chat', channel: msg.channel, name: row.display_name, guild: client.guildTag, trophies: row.trophies, text, at: now(),
  };
  q.addChat.run(key, client.id, message.name, message.guild, message.trophies, text, message.at);
  if (Math.random() < 0.02) q.trimChat.run(key, key);
  for (const other of clients.values()) {
    if (channelKey(other, msg.channel) === key) send(other, message);
  }
}

// --- Matchmaking ---------------------------------------------------------------------------------

function seatInfo(client, msg) {
  client.name = cleanName(msg.name) || client.name;
  if (isRude(client.name)) client.name = 'Runner';
  client.look = msg.look && typeof msg.look === 'object' ? msg.look : {};
}

function joinQueue(client, msg) {
  if (client.match || queue.some((e) => e.client === client)) return;
  leaveRoom(client);
  seatInfo(client, msg);
  const row = q.userById.get(client.id);
  client.trophies = row.trophies;
  queue.push({ client, at: Date.now(), map: typeof msg.map === 'string' ? msg.map.slice(0, 40) : '' });
}

function leaveQueue(client) {
  const i = queue.findIndex((e) => e.client === client);
  if (i >= 0) queue.splice(i, 1);
}

function tickQueue() {
  while (queue.length >= SEATS) {
    startFromQueue(queue.splice(0, SEATS));
  }
  if (queue.length > 0 && Date.now() - queue[0].at >= QUEUE_WAIT * 1000) {
    startFromQueue(queue.splice(0, queue.length));
  }
  const waited = queue.length > 0 ? (Date.now() - queue[0].at) / 1000 : 0;
  for (const entry of queue) {
    send(entry.client, { t: 'queue', found: queue.length, needed: SEATS, waited, wait_total: QUEUE_WAIT });
  }
}

function startFromQueue(entries) {
  // Strongest and weakest alternate, so the two teams come out about even.
  const players = entries.map((e) => e.client).sort((a, b) => b.trophies - a.trophies);
  const wanted = entries.map((e) => e.map).filter(Boolean);
  const map = wanted.length ? wanted[crypto.randomInt(wanted.length)] : '';
  const avg = players.reduce((sum, c) => sum + c.trophies, 0) / players.length;
  const humans = players.map((client, i) => ({ client, team: i % 2 }));
  startMatch(humans, map, Math.max(0.32, Math.min(0.32 + avg / 3500, 0.95)), true);
}

const BOT_FIRST = ['Kuya', 'Ate', 'Bunso', 'Tito', 'Tita', 'Lolo', 'Lola', 'Totoy', 'Nene', 'Boss', 'Pare', 'Mare', 'Idol', 'Sir', 'Kap'];
const BOT_LAST = ['Ben', 'Joy', 'Ricky', 'Gina', 'Dodong', 'Inday', 'Jun', 'Baby', 'Bong', 'Rey', 'Ling', 'Nonoy', 'Kiko', 'Mayang', 'Tess', 'Popoy', 'Waldo', 'Pidoy'];

/** humans: [{client, team}]. Empty seats become AI. Seat numbers alternate teams: even is team 0. */
function startMatch(humans, map, skill, ranked) {
  const id = crypto.randomBytes(6).toString('hex');
  const seed = crypto.randomInt(1, 2147483646);
  const seats = [];
  const byTeam = [humans.filter((h) => h.team === 0), humans.filter((h) => h.team === 1)];
  const used = new Set();
  for (let i = 0; i < SEATS; i += 1) {
    const team = i % 2;
    const human = byTeam[team].shift();
    if (human) {
      seats.push({ id: i, name: human.client.name, team, bot: false, look: human.client.look });
      human.client.seat = i;
      human.client.match = id;
    } else {
      let name;
      do {
        name = `${BOT_FIRST[crypto.randomInt(BOT_FIRST.length)]} ${BOT_LAST[crypto.randomInt(BOT_LAST.length)]}`;
      } while (used.has(name));
      used.add(name);
      const botSkill = Math.max(0.05, Math.min(skill + (crypto.randomInt(21) - 10) / 100, 1));
      seats.push({ id: i, name, team, bot: true, skill: botSkill });
    }
  }
  const players = humans.map((h) => h.client);
  const match = { id, map, seed, seats, skill, ranked, players: new Map(players.map((c) => [c.seat, c])), host: players[0].seat, reports: new Map(), done: false, timer: null };
  matches.set(id, match);
  for (const client of players) {
    send(client, { t: 'match_start', match: id, map, seed, seats, you: client.seat, host: match.host, skill, ranked });
  }
  return match;
}

function onBinary(client, data) {
  if (!client.match || data.length < 2) return;
  const match = matches.get(client.match);
  if (!match) return;
  const kind = data[0];
  if (kind === 1) {
    // Snapshots only come from the host, and go to everyone else.
    if (client.seat !== match.host) return;
    for (const other of match.players.values()) {
      if (other !== client && other.ws.readyState === WebSocket.OPEN) other.ws.send(data, { binary: true });
    }
  } else if (kind === 2) {
    // Inputs go to the host. Nobody can speak for another seat: the server writes in the sender's seat.
    const host = match.players.get(match.host);
    if (host && host !== client && host.ws.readyState === WebSocket.OPEN && data.length >= 5) {
      const buf = Buffer.from(data);
      buf.writeFloatLE(client.seat, 1);
      host.ws.send(buf, { binary: true });
    }
  }
}

function onMatchEmote(client, msg) {
  const match = client.match ? matches.get(client.match) : null;
  if (!match) return;
  const emote = cleanName(msg.emote, 24);
  for (const other of match.players.values()) {
    if (other !== client) send(other, { t: 'match_emote', player: client.seat, emote });
  }
}

function leaveMatch(client) {
  const match = client.match ? matches.get(client.match) : null;
  client.match = null;
  const seat = client.seat;
  client.seat = -1;
  if (!match) return;
  match.players.delete(seat);
  if (match.done) return;
  if (match.players.size === 0) {
    closeMatch(match);
    return;
  }
  for (const other of match.players.values()) send(other, { t: 'match_left', player: seat });
  if (match.host === seat) {
    match.host = match.players.keys().next().value;
    for (const other of match.players.values()) send(other, { t: 'match_host', host: match.host });
  }
  if (match.reports.size > 0) maybeFinish(match);
}

function closeMatch(match) {
  if (match.timer) clearTimeout(match.timer);
  matches.delete(match.id);
}

/** Each player reports how the match ended; the most common report counts, so one device can't fake it. */
function onMatchEnd(client, msg) {
  const match = client.match ? matches.get(client.match) : null;
  if (!match || match.done || msg.match !== match.id) return;
  const winner = Number(msg.winner);
  if (![0, 1, 2].includes(winner)) return;
  match.reports.set(client.seat, { winner, mvp: Number(msg.mvp) });
  if (!match.timer) match.timer = setTimeout(() => finishMatch(match), RESULT_WAIT_MS);
  maybeFinish(match);
}

function maybeFinish(match) {
  if (match.reports.size >= match.players.size) finishMatch(match);
}

function finishMatch(match) {
  if (match.done) return;
  match.done = true;
  if (match.timer) clearTimeout(match.timer);
  const tally = new Map();
  for (const report of match.reports.values()) {
    const key = `${report.winner}:${report.mvp}`;
    tally.set(key, (tally.get(key) || 0) + 1);
  }
  let best = null;
  let bestCount = 0;
  for (const [key, count] of tally) {
    if (count > bestCount) {
      best = key;
      bestCount = count;
    }
  }
  const [winner, mvp] = best ? best.split(':').map(Number) : [2, -1];
  const humanCount = match.players.size;
  const t = now();
  for (const client of match.players.values()) {
    const seat = match.seats[client.seat];
    const won = seat.team === winner;
    const row = q.userById.get(client.id);
    let delta = 0;
    if (match.ranked) {
      delta = trophyDelta(won, winner === 2, client.seat === mvp, row.trophies);
      // Beating only AI is worth less than beating people.
      if (humanCount === 1 && delta > 0) delta = Math.ceil(delta * 0.6);
    }
    const trophies = Math.max(0, row.trophies + delta);
    q.setResult.run(trophies, Math.max(row.best_trophies, trophies), won ? 1 : 0, t, client.id);
    client.trophies = trophies;
    send(client, { t: 'match_result', match: match.id, winner, mvp, delta, trophies, ranked: match.ranked });
    client.match = null;
    client.seat = -1;
  }
  closeMatch(match);
}

/** Mirrors Ranks.trophy_delta in the game. */
function trophyDelta(won, draw, isMvp, trophies) {
  if (draw) return 2;
  let delta;
  if (won) delta = trophies < 1000 ? 12 : 9;
  else if (trophies < 100) delta = -2;
  else delta = trophies < 1000 ? -4 : -7;
  if (isMvp) delta += 3;
  return delta;
}

// --- Friend Rooms --------------------------------------------------------------------------------

const ROOM_LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function newRoomCode() {
  for (;;) {
    let code = '';
    for (let i = 0; i < 4; i += 1) code += ROOM_LETTERS[crypto.randomInt(ROOM_LETTERS.length)];
    if (!rooms.has(code)) return code;
  }
}

function roomView(room, viewer) {
  return {
    code: room.code, map: room.map, skill: room.skill, host: room.host.id, you: viewer.id,
    seats: room.members.map((m) => ({ id: m.client.id, name: m.client.name, team: m.team })),
  };
}

function sendRoom(room) {
  for (const member of room.members) send(member.client, { t: 'room', room: roomView(room, member.client) });
}

function roomCreate(client, msg) {
  if (client.match) return;
  leaveQueue(client);
  leaveRoom(client);
  seatInfo(client, msg);
  const room = {
    code: newRoomCode(), host: client, members: [{ client, team: 0 }],
    map: typeof msg.map === 'string' ? msg.map.slice(0, 40) : '',
    skill: Math.max(0.05, Math.min(Number(msg.skill) || 0.5, 1)),
  };
  rooms.set(room.code, room);
  client.room = room.code;
  sendRoom(room);
}

function roomJoin(client, msg) {
  if (client.match) return;
  const room = rooms.get(String(msg.code ?? '').toUpperCase().slice(0, 6));
  if (!room) {
    send(client, { t: 'room_error', message: "There's no room with that code." });
    return;
  }
  if (room.members.some((m) => m.client === client)) {
    sendRoom(room);
    return;
  }
  if (room.members.length >= SEATS) {
    send(client, { t: 'room_error', message: 'That room is full.' });
    return;
  }
  leaveQueue(client);
  leaveRoom(client);
  seatInfo(client, msg);
  const counts = [0, 0];
  for (const member of room.members) counts[member.team] += 1;
  room.members.push({ client, team: counts[0] <= counts[1] ? 0 : 1 });
  client.room = room.code;
  sendRoom(room);
}

function leaveRoom(client) {
  const room = client.room ? rooms.get(client.room) : null;
  client.room = null;
  if (!room) return;
  room.members = room.members.filter((m) => m.client !== client);
  send(client, { t: 'room_closed' });
  if (room.members.length === 0) {
    rooms.delete(room.code);
    return;
  }
  if (room.host === client) room.host = room.members[0].client;
  sendRoom(room);
}

function roomTeam(client, msg) {
  const room = client.room ? rooms.get(client.room) : null;
  const team = Number(msg.team);
  if (!room || (team !== 0 && team !== 1)) return;
  if (room.members.filter((m) => m.team === team).length >= TEAM_SIZE) return;
  const member = room.members.find((m) => m.client === client);
  if (member) member.team = team;
  sendRoom(room);
}

function roomConfig(client, msg) {
  const room = client.room ? rooms.get(client.room) : null;
  if (!room || room.host !== client) return;
  if (typeof msg.map === 'string') room.map = msg.map.slice(0, 40);
  if (Number.isFinite(Number(msg.skill))) room.skill = Math.max(0.05, Math.min(Number(msg.skill), 1));
  sendRoom(room);
}

function roomStart(client) {
  const room = client.room ? rooms.get(client.room) : null;
  if (!room || room.host !== client) return;
  rooms.delete(room.code);
  const humans = room.members.map((m) => ({ client: m.client, team: m.team }));
  for (const member of room.members) member.client.room = null;
  // The host goes first, so the match runs on the device that started it.
  humans.sort((a, b) => (a.client === client ? -1 : b.client === client ? 1 : 0));
  // Private: friends can't farm trophies off each other.
  startMatch(humans, room.map, room.skill, false);
}

// --- Housekeeping --------------------------------------------------------------------------------

const queueTimer = setInterval(tickQueue, 1000);
const onlineTimer = setInterval(() => broadcast({ t: 'online', count: clients.size }), 15000);
const pingTimer = setInterval(() => {
  for (const client of clients.values()) {
    if (!client.alive) {
      client.ws.terminate();
      continue;
    }
    client.alive = false;
    client.ws.ping();
  }
}, 30000);

function stop(done) {
  clearInterval(queueTimer);
  clearInterval(onlineTimer);
  clearInterval(pingTimer);
  for (const client of wss.clients) client.terminate();
  wss.close();
  server.close(() => {
    db.close();
    done?.();
  });
}
function shutdown() {
  stop(() => process.exit(0));
  setTimeout(() => process.exit(0), 3000).unref();
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

server.listen(PORT, () => console.log(`Capture the Base server on port ${PORT}`));

module.exports = { server, stop };
