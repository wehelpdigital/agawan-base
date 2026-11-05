"""Builds the game's icons from game-icons.net silhouettes (CC BY 3.0, credited in the game).

Each powerup gets a chunky badge in its category colour; interface icons are plain white shapes that
the UI tints. Run from the project root:

    python tools/gen_icons.py <folder to cache the downloaded svgs in>
"""
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = "https://raw.githubusercontent.com/game-icons/icons/master/%s.svg"

POWER = {
    "rocket_slippers": "lorc/rocket-flight", "blink_step": "lorc/teleport", "super_hop": "delapouite/jump-across",
    "grapple_vine": "lorc/grapple", "tailwind": "lorc/windy-stripes", "ghost_sprint": "lorc/sprint",
    "home_run": "delapouite/player-base", "coco_boost": "delapouite/energy-tank", "freeze_ray": "lorc/ice-bolt",
    "coconut_shot": "delapouite/coconuts", "fishing_net": "lorc/fishing-net", "slime_ball": "delapouite/slime",
    "sky_zap": "lorc/focused-lightning", "thunderstorm": "lorc/thunder-struck", "shockwave": "lorc/vibrating-ball",
    "big_magnet": "lorc/magnet", "mini_twister": "lorc/tornado", "black_hole": "lorc/black-hole-bolas",
    "rolling_barrel": "delapouite/barrel", "ricochet_disc": "lorc/disc", "hot_trail": "lorc/celebration-fire",
    "earthquake": "lorc/earth-crack", "meteor_shower": "lorc/meteor-impact", "giant_growth": "delapouite/giant",
    "overcharge": "lorc/bottled-bolt", "chain_tag": "willdabeast/chain-lightning", "bubble_shield": "lorc/bubble-field",
    "popup_wall": "delapouite/stone-wall", "base_lock": "delapouite/locked-door", "sentry_buddy": "delapouite/walking-turret",
    "snare_ring": "lorc/wolf-trap", "pop_mines": "lorc/land-mine", "slow_dome": "lorc/sands-of-time",
    "thorn_hedge": "lorc/thorny-vine", "mirror_shield": "lorc/mirror-mirror", "fresh_start": "delapouite/clockwise-rotation",
    "switcheroo": "lorc/body-swapping", "stale_curse": "lorc/thunder-skull", "squid_ink": "lorc/squid",
    "mixup_hex": "delapouite/knocked-out-stars", "soap_slick": "delapouite/soap", "scare_horn": "lorc/hunting-horn",
    "decoy_squad": "lorc/ghost-ally", "invisi_cloak": "delapouite/invisible", "ghost_mode": "lorc/ghost",
    "tiny_time": "delapouite/mouse", "jailbreak": "skoll/breaking-chain", "fiesta_rush": "delapouite/party-flags",
    "team_refresh": "delapouite/time-synchronization", "group_hug": "delapouite/heart-shield", "radar_ping": "lorc/radar-sweep",
    "capture_boost": "delapouite/flag-objective", "power_rain": "lorc/raining",
}
CAT_COLORS = {"speed": ("35d07f", "1a9c58"), "attack": ("ff5a4e", "c9302a"), "defend": ("3aa6ff", "1a6fd0"),
              "trick": ("b768ff", "7f38d6"), "team": ("ffc21f", "e48f0a")}
UI = {
    "trophy": "delapouite/trophy-cup", "coin": "delapouite/two-coins", "gem": "lorc/gems", "star": "delapouite/round-star",
    "gear": "lorc/gears", "chat": "delapouite/chat-bubble", "guild": "delapouite/tower-flag", "shop": "delapouite/shop",
    "avatar": "delapouite/person", "map": "lorc/treasure-map", "rank": "delapouite/star-medal", "play": "guard13007/play-button",
    "crown": "lorc/crown", "shield": "lorc/bolt-shield", "flag": "delapouite/flag-objective", "dash": "lorc/sprint",
    "power": "lorc/rolling-energy", "cage": "delapouite/cage", "back": "delapouite/fast-backward-button", "sound": "delapouite/sound-on",
    "mute": "delapouite/sound-off", "music": "delapouite/musical-notes", "help": "lorc/gift-of-knowledge", "emote": "delapouite/party-popper",
    "hat": "delapouite/party-hat", "trail": "lorc/boot-prints", "aura": "lorc/embrassed-energy", "burst": "lorc/crowned-explosion",
    "frame": "delapouite/ribbon-medal", "title": "delapouite/medallist", "dance": "lorc/cartwheel", "backpack": "delapouite/backpack",
    "skull": "lorc/crowned-skull", "robot": "delapouite/walking-turret", "exit": "delapouite/exit-door",
    "lock": "delapouite/dial-padlock", "mask": "lorc/tribal-mask", "top": "delapouite/t-shirt", "pants": "lorc/trousers",
    "shoes": "delapouite/converse-shoe", "gloves": "delapouite/gloves", "people": "delapouite/three-friends", "gift": "delapouite/present", "swords": "lorc/crossed-swords",
}
# Simple shapes drawn here, for things the set has no clean glyph for.
DRAWN = {
    "check": "M70 270 L200 400 L442 130 L392 86 L198 300 L118 222 Z",
    "close": "M120 70 L256 206 L392 70 L442 120 L306 256 L442 392 L392 442 L256 306 L120 442 L70 392 L206 256 L70 120 Z",
    "plus": "M216 80 H296 V216 H432 V296 H296 V432 H216 V296 H80 V216 H216 Z",
    "arrow_left": "M300 70 L356 126 L226 256 L356 386 L300 442 L114 256 Z",
    "arrow_right": "M212 70 L156 126 L286 256 L156 386 L212 442 L398 256 Z",
    "pause": "M130 80 H226 V432 H130 Z M286 80 H382 V432 H286 Z",
    "search": "M216 60 A156 156 0 1 0 216 372 A156 156 0 1 0 216 60 Z M216 124 A92 92 0 1 1 216 308 A92 92 0 1 1 216 124 Z M326 280 L452 406 L406 452 L280 326 Z",
    "menu": "M70 110 H442 V180 H70 Z M70 221 H442 V291 H70 Z M70 332 H442 V402 H70 Z",
}


def fetch(name: str, cache: Path) -> str:
    target = cache / (name.replace("/", "__") + ".svg")
    if not target.exists():
        with urllib.request.urlopen(RAW % name, timeout=30) as r:
            target.write_bytes(r.read())
    return target.read_text(encoding="utf-8")


def glyph_paths(svg: str) -> str:
    """Only the path data, never anything else from a downloaded file; the first path is the square."""
    found = re.findall(r'<path\b[^>]*\bd="([^"]+)"', svg)
    if not found:
        raise ValueError("no paths")
    if len(found) > 1 and found[0].replace(" ", "").lower().startswith(("m0,0h512", "m00h512")):
        found = found[1:]
    return " ".join(d for d in found if re.fullmatch(r"[-0-9.,eEMmLlHhVvCcSsQqTtAaZz \n\t]+", d))


def badge(d: str, top: str, low: str, tier: int) -> str:
    ink = "24135f"
    rim = {1: "ffffff", 2: "ffffff", 3: "fff176"}[tier]
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 160 160">\n'
        f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#{top}"/>'
        f'<stop offset="1" stop-color="#{low}"/></linearGradient></defs>\n'
        f'<rect x="6" y="12" width="148" height="142" rx="38" fill="#{ink}"/>\n'
        f'<rect x="6" y="6" width="148" height="142" rx="38" fill="#{ink}"/>\n'
        '<rect x="14" y="14" width="132" height="126" rx="30" fill="url(#g)"/>\n'
        '<path d="M22 56 C 22 30, 38 20, 62 20 L 98 20 C 122 20, 138 30, 138 56 C 110 42, 50 42, 22 56 Z" fill="#fff" opacity="0.28"/>\n'
        f'<g transform="translate(29 25) scale(0.2)"><path d="{d}" fill="#{ink}" opacity="0.45" transform="translate(0 22)"/>'
        f'<path d="{d}" fill="#{rim}" stroke="#{ink}" stroke-width="10" paint-order="stroke"/></g>\n'
        "</svg>\n"
    )


def plain(d: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 512 512">'
        f'<path d="{d}" fill="#fff"/></svg>\n'
    )


def main() -> None:
    cache = Path(sys.argv[1])
    cache.mkdir(parents=True, exist_ok=True)
    db = (ROOT / "core/data/Powerups.gd").read_text(encoding="utf-8")
    defs = {}
    for m in re.finditer(r'"id": "(\w+)", "name": "[^"]+", "cat": "(\w+)", "tier": (\d)', db):
        defs[m.group(1)] = (m.group(2), int(m.group(3)))
    missing = set(defs) - set(POWER)
    if missing:
        raise SystemExit(f"no icon chosen for: {sorted(missing)}")
    power_dir = ROOT / "assets/icons/power"
    ui_dir = ROOT / "assets/icons/ui"
    power_dir.mkdir(parents=True, exist_ok=True)
    ui_dir.mkdir(parents=True, exist_ok=True)
    failed = []
    for pid, (cat, tier) in defs.items():
        try:
            d = glyph_paths(fetch(POWER[pid], cache))
            top, low = CAT_COLORS[cat]
            (power_dir / f"{pid}.svg").write_text(badge(d, top, low, tier), encoding="utf-8")
        except Exception as e:  # Listed at the end, so one bad name doesn't stop the batch.
            failed.append((pid, POWER[pid], str(e)))
    for uid, name in UI.items():
        try:
            (ui_dir / f"{uid}.svg").write_text(plain(glyph_paths(fetch(name, cache))), encoding="utf-8")
        except Exception as e:
            failed.append((uid, name, str(e)))
    for uid, d in DRAWN.items():
        (ui_dir / f"{uid}.svg").write_text(plain(d), encoding="utf-8")
    print(f"powers {len(defs)}, ui {len(UI) + len(DRAWN)}, failed {len(failed)}")
    for f in failed:
        print("  ", f)


if __name__ == "__main__":
    main()
