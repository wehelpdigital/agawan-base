"""Copies the sounds the code names, and the music tracks, from a folder of licence-checked audio.

The sources and their licences are listed in assets/audio/CREDITS.md. Run this again after using a new
sound in the code; it only copies what is referenced, so the download stays small:

    python tools/copy_audio.py <folder with sfx/ and themes/>
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRACKS = {
    "tropical_island_meet_and_greet", "latin_peppy_pepe", "tropical_tiki_bar_mixer", "tropical_beachfront_celebration",
    "funk_make_funk", "gamer_hard_mode", "gamer_final_level", "gamer_coins", "kids_pixel_peeker_polka", "latin_samba_isobel",
    "rock_sock_hop", "rock_exhilarate", "cartoon_sneaky_snitch", "cartoon_jaunty_gumption",
}


def main() -> None:
    src = Path(sys.argv[1])
    available = {p.stem: p for p in (src / "sfx").glob("*.ogg")}
    words = set()
    for code in list(ROOT.glob("core/**/*.gd")) + list(ROOT.glob("scenes/**/*.gd")) + list(ROOT.glob("ui/**/*.gd")) + list(ROOT.glob("autoload/*.gd")):
        words.update(re.findall(r'"([a-z0-9_]+)"', code.read_text(encoding="utf-8")))
    wanted = sorted(words & set(available))
    sfx_dir = ROOT / "assets/audio/sfx"
    music_dir = ROOT / "assets/audio/music"
    sfx_dir.mkdir(parents=True, exist_ok=True)
    music_dir.mkdir(parents=True, exist_ok=True)
    for name in wanted:
        shutil.copyfile(available[name], sfx_dir / f"{name}.ogg")
    for old in sfx_dir.glob("*.ogg"):
        if old.stem not in wanted:
            old.unlink()
    for track in TRACKS:
        shutil.copyfile(src / "themes" / f"{track}.ogg", music_dir / f"{track}.ogg")
    size = sum(p.stat().st_size for p in sfx_dir.glob("*.ogg"))
    music = sum(p.stat().st_size for p in music_dir.glob("*.ogg"))
    print(f"sfx {len(wanted)} files {size // 1024} KB; music {len(TRACKS)} tracks {music // 1024} KB")


if __name__ == "__main__":
    main()
