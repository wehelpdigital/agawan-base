# Capture the Base

5 vs 5 arcade tag in 3D, from the traditional Filipino game of **Agawan Base** (Prisoner's Base).
Godot 4.7 client (Compatibility renderer: web, Android, desktop) and one small Node server for everything
online.

## The game

- **The fresher wins.** Whoever left their base most recently tags the other on contact. A green arrow over
  an enemy means you can tag them; a red sign means they can tag you. Your own base makes you fresh, and it
  is safe, but the pad pops you off after 5 seconds (our rule: camping is no fun on a screen).
- **Jail and rescue.** Tagged players go to the jail beside the tagger's base. Tap to break out sooner, or a
  free teammate touches the jail and frees everyone. Rescuers and the freed get a "free walk" home.
- **Capture.** Stand on the enemy base to capture it, or jail the whole enemy team at once. First to 3 points,
  or the most when time runs out, then sudden death, then whoever took the most prisoners.
- **Ways to play:** online with whoever's around (AI takes any empty seat), Friend Rooms with a share code
  (same team or opposing, AI fills the rest), or against AI at four levels.
- **53 power cards**, hidden in crystals that drop at random: `core/data/Powerups.gd`. **56 maps** (14 looks, 16 layouts):
  `core/data/Maps.gd`.
- **The shop** is sorted by accessory: masks, head gear, tops, pants, shoes, gloves, backs, run styles, dances,
  emotes, trails, auras, tag effects, frames, titles. Avatars and colours are one category among them.
  Everything is earned with coins and gems from playing: `core/data/Cosmetics.gd`.
- **Also:** leagues and a global leaderboard, guilds with their own chat, global chat, daily rewards and quests.

## Run it

Open the folder in Godot 4.7 and press Play. Offline it plays against the AI. For the online features:

```text
cd server
npm install
npm start                     # http://127.0.0.1:8787 (needs Node 22.13+)
```

Then run the game with `-- --server=http://127.0.0.1:8787`, or enter the address in Settings > More.

**The line.** The field is split down the middle. On your own side you can tag any enemy; over the line, they can tag you. A fountain or a Fresh card charges you for a few seconds, and then you can tag anyone anywhere.

**Controls.** Touch: left thumb runs, right thumb dashes and plays cards (tap to auto-aim, drag to aim).
Keyboard: WASD or arrows, Space to dash, E to use a card, right-click to aim, 1-4 for emotes.
Controller: left stick, A to dash, X to use, right stick to aim.

## Layout

```text
autoload/   Settings, Profile (wallet, items, quests), Audio, Net (HTTP + WebSocket)
core/sim/   Sim: the rules, no scenes, runs anywhere. BotBrain: the AI.
core/data/  Powerups, Maps, Cosmetics, Ranks, Names: everything data-driven
gfx/        MeshKit (procedural meshes), PropKit, ArenaBuilder, Avatar3D + AvatarParts, FxField, shaders
scenes/     Main, and match/: MatchRunner, MatchView (3D), Hud, Minimap
ui/         UiKit, UiRoot, GameButton, screens/
server/     Node server (server.js), tests, public/ (the exported web game)
tests/      SimTest, OnlineE2E, UiShots, ZoomTest, MatchShot, ThumbBaker, AvatarShot, ItemAudit (every item on any avatar),
            SpinShot, TrickShot, PropSheet, IconSheet, GagSheet (pictures to check by eye)
tools/      gen_art (logo, icons, atlas), gen_icons, copy_audio, publish_web
web/        The web page around the game (edit shell.src.html)
```

All 3D art is generated in code. Every prop, avatar and accessory is a few lines in `PropKit`, `Avatar3D` or
`AvatarParts`, merged into single meshes so phones stay fast.

Online matches run on one player's device using the same `Sim` as practice; the server relays snapshots and
inputs. If the host drops, another player takes over from the last snapshot. If a player loses the server, the
match carries on locally against AI with no trophies. Trophies come from what the players in a match report
(most common answer wins), and Friend Room matches earn none.

## Tests

```text
godot --headless --path . --script res://tests/SimTest.gd        # rules, maps, every powerup, full bot matches
cd server && npm test                                            # accounts, guilds, chat, queue, rooms, results
godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 390x844 res://tests/UiShots.tscn -- --out=<dir> --tag=phone --device=phone_portrait
godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/MatchShot.tscn -- --map=barrio_plaza --out=<dir> --all-powers
```

`tests/OnlineE2E.gd` plays two real clients through a running server; its header has the commands.
Always pass `--audio-driver Dummy` to windowed test runs so they stay silent.

## Publish

**Web.** `python tools/publish_web.py <godot console exe>` exports into `server/public` (gzipped, about 26 MB to
download). Commit that folder and the server serves the game. After changing heroes, accessories or map looks,
rebuild the pictures first with `tests/ThumbBaker.tscn`.

**Server.** Deploy the root `Dockerfile` to any host that runs containers and keeps a disk (Render, Railway, Fly,
a VPS). Mount a volume at `/data` for the SQLite database, or accounts vanish on each deploy. Settings:
`PORT`, `DB_PATH`, `PUBLIC_DIR`, `QUEUE_WAIT_SECONDS`. It needs WebSockets and one instance only.

**Android and desktop builds** need the server's address: set `DEFAULT_SERVER` in `autoload/Net.gd` before export.
The web build finds its server by itself. Presets are in `export_presets.cfg`; the Android preset needs a
keystore through the `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables. iOS needs a Mac with Xcode.

## Art and IP

Avatars, maps, logo and props are original to this game. The look is in the broad family of bright arcade
brawlers; no characters, logos or art are taken from any other game. Audio and icon sources are in
`assets/audio/CREDITS.md` and on the in-game Credits screen, which CC BY requires us to keep. Fonts are SIL OFL.
