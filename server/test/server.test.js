'use strict';
// End-to-end tests against a real server on a throwaway database: npm test

const test = require('node:test');
const assert = require('node:assert');
const os = require('node:os');
const path = require('node:path');
const fs = require('node:fs');
const { WebSocket } = require('ws');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ctb-test-'));
process.env.DB_PATH = path.join(dir, 'test.db');
process.env.PORT = '18787';
process.env.QUEUE_WAIT_SECONDS = '1';
process.env.PUBLIC_DIR = dir;
const { server, stop } = require('../server.js');

const BASE = 'http://127.0.0.1:18787';

async function api(method, route, body, token) {
  const res = await fetch(BASE + route, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, data: await res.json() };
}

async function guest(name) {
  const { status, data } = await api('POST', '/api/auth/guest', { name });
  assert.strictEqual(status, 200);
  return data;
}

function socket(token) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:18787/ws?token=${token}`);
    const inbox = [];
    const waiters = [];
    ws.on('message', (data, isBinary) => {
      const msg = isBinary ? { binary: data } : JSON.parse(data.toString());
      const i = waiters.findIndex((w) => w.test(msg));
      if (i >= 0) waiters.splice(i, 1)[0].resolve(msg);
      else inbox.push(msg);
    });
    ws.on('open', () => resolve({
      ws,
      send: (obj) => ws.send(JSON.stringify(obj)),
      next: (test, ms = 3000) => new Promise((res, rej) => {
        const check = typeof test === 'string' ? (m) => m.t === test : test;
        const j = inbox.findIndex(check);
        if (j >= 0) {
          res(inbox.splice(j, 1)[0]);
          return;
        }
        const timer = setTimeout(() => rej(new Error(`timed out waiting for ${test}`)), ms);
        waiters.push({ test: check, resolve: (m) => { clearTimeout(timer); res(m); } });
      }),
    }));
    ws.on('error', reject);
  });
}

test.after(() => new Promise((resolve) => {
  server.closeAllConnections?.();
  stop(resolve);
}));

test('accounts: guest, profile, register, log in on another device, wrong password', async () => {
  const me = await guest('Lani');
  assert.ok(me.token);
  assert.strictEqual(me.user.display_name, 'Lani');
  await api('PUT', '/api/me', { name: 'Lani2', level: 4, look: { mask: 'panda' }, save: { coins: 500, saved_at: 5 } }, me.token);
  const got = await api('GET', '/api/me', null, me.token);
  assert.strictEqual(got.data.user.display_name, 'Lani2');
  assert.strictEqual(got.data.user.save.coins, 500);
  const short = await api('POST', '/api/auth/register', { username: 'lani', password: 'short' }, me.token);
  assert.strictEqual(short.status, 400);
  const reg = await api('POST', '/api/auth/register', { username: 'lani_ph', password: 'correct horse' }, me.token);
  assert.strictEqual(reg.status, 200);
  const bad = await api('POST', '/api/auth/login', { username: 'lani_ph', password: 'wrong password' });
  assert.strictEqual(bad.status, 401);
  const ok = await api('POST', '/api/auth/login', { username: 'LANI_PH', password: 'correct horse' });
  assert.strictEqual(ok.status, 200);
  assert.strictEqual(ok.data.user.save.coins, 500);
  assert.strictEqual((await api('GET', '/api/me', null, 'nonsense')).status, 401);
});

test('rude names are refused', async () => {
  const me = await guest('putangina');
  assert.ok(me.user.display_name.startsWith('Runner'));
});

test('guilds: create, join, full flow, leader passes on, empty guild goes away', async () => {
  const a = await guest('Ana');
  const b = await guest('Ben');
  const made = await api('POST', '/api/guilds', { name: 'Barrio Kings', tag: 'bk', about: 'hi', badge: 2 }, a.token);
  assert.strictEqual(made.status, 200);
  const id = made.data.guild.id;
  assert.strictEqual((await api('POST', '/api/guilds', { name: 'Barrio Kings', tag: 'bk2' }, b.token)).status, 409);
  assert.strictEqual((await api('POST', `/api/guilds/${id}/join`, {}, b.token)).status, 200);
  const page = await api('GET', `/api/guilds/${id}`, null, a.token);
  assert.strictEqual(page.data.members.length, 2);
  assert.strictEqual((await api('POST', '/api/guilds/kick', { user_id: a.user.id }, b.token)).status, 403);
  const found = await api('GET', '/api/guilds?q=Barrio');
  assert.strictEqual(found.data.guilds[0].members, 2);
  await api('POST', '/api/guilds/leave', {}, a.token);
  const after = await api('GET', `/api/guilds/${id}`, null, b.token);
  assert.strictEqual(after.data.guild.leader_id, b.user.id);
  await api('POST', '/api/guilds/leave', {}, b.token);
  assert.strictEqual((await api('GET', `/api/guilds/${id}`, null, b.token)).status, 404);
});

test('chat: global messages reach everyone, words are filtered, flooding stops', async () => {
  const a = await guest('Chatty');
  const b = await guest('Listener');
  const sa = await socket(a.token);
  const sb = await socket(b.token);
  sa.send({ t: 'chat', channel: 'global', text: 'hello puta world' });
  const msg = await sb.next('chat');
  assert.strictEqual(msg.name, 'Chatty');
  assert.ok(!msg.text.includes('puta'));
  sb.send({ t: 'chat_history', channel: 'global' });
  const history = await sb.next('chat_history');
  assert.ok(history.messages.some((m) => m.name === 'Chatty'));
  for (let i = 0; i < 10; i += 1) sa.send({ t: 'chat', channel: 'global', text: `spam ${i}` });
  await new Promise((r) => setTimeout(r, 200));
  sb.send({ t: 'chat_history', channel: 'global' });
  const later = await sb.next('chat_history');
  assert.ok(later.messages.filter((m) => m.text.startsWith('spam')).length <= 4);
  sa.ws.close();
  sb.ws.close();
});

test('matchmaking: alone in the queue, the empty seats go to AI, and a win earns trophies', async () => {
  const a = await guest('Solo');
  const sa = await socket(a.token);
  sa.send({ t: 'queue', map: 'barrio_plaza', name: 'Solo', look: {} });
  const start = await sa.next('match_start', 5000);
  assert.strictEqual(start.seats.length, 10);
  assert.strictEqual(start.seats.filter((s) => s.bot).length, 9);
  assert.strictEqual(start.host, start.you);
  assert.strictEqual(start.ranked, true);
  sa.send({ t: 'match_end', match: start.match, winner: start.seats[start.you].team, mvp: start.you });
  const result = await sa.next('match_result');
  assert.ok(result.delta > 0);
  const me = await api('GET', '/api/me', null, a.token);
  assert.strictEqual(me.data.user.trophies, result.trophies);
  assert.strictEqual(me.data.user.games, 1);
  sa.ws.close();
});

test('matchmaking: two players land in one match, data flows, the host hands over', async () => {
  const a = await guest('Host');
  const b = await guest('Other');
  const sa = await socket(a.token);
  const sb = await socket(b.token);
  sa.send({ t: 'queue', map: '', name: 'Host', look: {} });
  sb.send({ t: 'queue', map: '', name: 'Other', look: {} });
  const ma = await sa.next('match_start', 5000);
  const mb = await sb.next('match_start', 5000);
  assert.strictEqual(ma.match, mb.match);
  assert.strictEqual(ma.seats.filter((s) => !s.bot).length, 2);
  const [hostSock, otherSock, host, other] = ma.you === ma.host ? [sa, sb, ma, mb] : [sb, sa, mb, ma];
  hostSock.ws.send(Buffer.from([1, 9, 9, 9]), { binary: true });
  const snap = await otherSock.next((m) => m.binary);
  assert.strictEqual(snap.binary[0], 1);
  // An input is stamped with the sender's real seat, whatever the sender claims.
  const claim = Buffer.alloc(33);
  claim[0] = 2;
  claim.writeFloatLE(7, 1);
  otherSock.ws.send(claim, { binary: true });
  const input = await hostSock.next((m) => m.binary);
  assert.strictEqual(input.binary.readFloatLE(1), other.you);
  // Only the host may send snapshots.
  otherSock.ws.send(Buffer.from([1, 1, 1, 1]), { binary: true });
  await new Promise((r) => setTimeout(r, 100));
  hostSock.ws.close();
  const newHost = await otherSock.next('match_host');
  assert.strictEqual(newHost.host, other.you);
  assert.notStrictEqual(host.you, other.you);
  otherSock.ws.close();
});

test('Friend Rooms: code, teams with or against, AI fills the rest, no trophies', async () => {
  const a = await guest('RoomHost');
  const b = await guest('Friend');
  const c = await guest('Stranger');
  const sa = await socket(a.token);
  const sb = await socket(b.token);
  const sc = await socket(c.token);
  sc.send({ t: 'room_join', code: 'ZZZZ', name: 'Stranger', look: {} });
  assert.match((await sc.next('room_error')).message, /no room/);
  sa.send({ t: 'room_create', map: 'beach_plaza', skill: 0.75, name: 'RoomHost', look: {} });
  const made = await sa.next('room');
  assert.strictEqual(made.room.code.length, 4);
  assert.strictEqual(made.room.host, made.room.you);
  sb.send({ t: 'room_join', code: made.room.code.toLowerCase(), name: 'Friend', look: {} });
  let view = await sb.next('room');
  assert.strictEqual(view.room.seats.length, 2);
  assert.notStrictEqual(view.room.seats[0].team, view.room.seats[1].team);
  // Friend moves to the host's team: playing together.
  sb.send({ t: 'room_team', team: 0 });
  view = await sb.next((m) => m.t === 'room' && m.room.seats.every((s) => s.team === 0));
  // Only the host can start or change settings.
  sb.send({ t: 'room_start' });
  sb.send({ t: 'room_config', skill: 0.1 });
  sa.send({ t: 'room_config', map: 'volcano_plaza', skill: 0.98 });
  await sa.next((m) => m.t === 'room' && m.room.map === 'volcano_plaza');
  sa.send({ t: 'room_start' });
  const ma = await sa.next('match_start');
  const mb = await sb.next('match_start');
  assert.strictEqual(ma.map, 'volcano_plaza');
  assert.strictEqual(ma.ranked, false);
  assert.strictEqual(ma.seats[ma.you].team, ma.seats[mb.you].team);
  assert.strictEqual(ma.seats.filter((s) => s.bot).length, 8);
  assert.strictEqual(ma.seats.filter((s) => s.team === 0).length, 5);
  assert.strictEqual(ma.you, ma.host);
  const team = ma.seats[ma.you].team;
  sa.send({ t: 'match_end', match: ma.match, winner: team, mvp: ma.you });
  sb.send({ t: 'match_end', match: ma.match, winner: team, mvp: ma.you });
  const result = await sb.next('match_result');
  assert.strictEqual(result.delta, 0);
  assert.strictEqual(result.ranked, false);
  sa.ws.close();
  sb.ws.close();
  sc.ws.close();
});

test('results: the majority report wins, so one device cannot fake a win', async () => {
  const names = ['One', 'Two', 'Three'];
  const players = await Promise.all(names.map((n) => guest(`Fair${n}`)));
  const socks = await Promise.all(players.map((p) => socket(p.token)));
  socks[0].send({ t: 'room_create', map: '', skill: 0.5, name: 'FairOne', look: {} });
  const code = (await socks[0].next('room')).room.code;
  for (const i of [1, 2]) {
    socks[i].send({ t: 'room_join', code, name: names[i], look: {} });
    await socks[i].next('room');
  }
  socks[0].send({ t: 'room_start' });
  const starts = await Promise.all(socks.map((s) => s.next('match_start')));
  const id = starts[0].match;
  socks[0].send({ t: 'match_end', match: id, winner: 0, mvp: 0 });
  socks[1].send({ t: 'match_end', match: id, winner: 1, mvp: 1 });
  socks[2].send({ t: 'match_end', match: id, winner: 1, mvp: 1 });
  const result = await socks[0].next('match_result');
  assert.strictEqual(result.winner, 1);
  socks.forEach((s) => s.ws.close());
});

test('leaderboard ranks players and guilds', async () => {
  const board = await api('GET', '/api/leaderboard?scope=players&limit=5');
  assert.ok(board.data.rows.length > 0);
  for (let i = 1; i < board.data.rows.length; i += 1) {
    assert.ok(board.data.rows[i - 1].trophies >= board.data.rows[i].trophies);
  }
  const g = await guest('GuildBoss');
  await api('POST', '/api/guilds', { name: 'Top Guild', tag: 'TOP' }, g.token);
  const guilds = await api('GET', '/api/leaderboard?scope=guilds');
  assert.ok(guilds.data.rows.some((r) => r.tag === 'TOP'));
});

test('the web game: serves files, keeps out of other folders', async () => {
  fs.writeFileSync(path.join(dir, 'index.html'), '<h1>hi</h1>');
  const page = await fetch(`${BASE}/`);
  assert.strictEqual(await page.text(), '<h1>hi</h1>');
  const res = await fetch(`${BASE}/%2e%2e/%2e%2e/etc/passwd`);
  assert.ok(res.status === 403 || res.status === 404);
});
