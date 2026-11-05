"""Builds the web game into server/public, ready for the game server to serve.

Exports with Godot, then gzips the big files (the server sends them compressed, which cuts the download
to about a quarter). Run from the project root:

    python tools/publish_web.py [path to the Godot console exe]
"""
import base64
import gzip
import io
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GODOT = sys.argv[1] if len(sys.argv) > 1 else "godot"
BUILD = ROOT / "build/web"
PUBLIC = ROOT / "server/public"


def make_shell() -> None:
    logo = Image.open(ROOT / "assets/brand/logo.png").convert("RGBA")
    logo.thumbnail((620, 400), Image.LANCZOS)
    data = io.BytesIO()
    logo.save(data, "WEBP", quality=82)
    uri = "data:image/webp;base64," + base64.b64encode(data.getvalue()).decode("ascii")
    src = (ROOT / "web/shell.src.html").read_text(encoding="utf-8")
    (ROOT / "web/shell.html").write_text(src.replace("%LOGO%", uri), encoding="utf-8", newline="\n")


def export() -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--audio-driver", "Dummy", "--import"], check=True, capture_output=True)
    result = subprocess.run([GODOT, "--headless", "--path", str(ROOT), "--audio-driver", "Dummy", "--export-release", "Web", str(BUILD / "index.html")], capture_output=True, text=True)
    if result.returncode != 0 or not (BUILD / "index.wasm").exists():
        print(result.stdout[-2000:], result.stderr[-2000:])
        raise SystemExit("Export failed")


def publish() -> None:
    if PUBLIC.exists():
        shutil.rmtree(PUBLIC)
    PUBLIC.mkdir(parents=True)
    total_raw = 0
    total_sent = 0
    for file in sorted(BUILD.iterdir()):
        if not file.is_file():
            continue
        raw = file.read_bytes()
        total_raw += len(raw)
        if file.suffix in (".wasm", ".pck", ".js", ".html"):
            packed = gzip.compress(raw, compresslevel=9, mtime=0)
            (PUBLIC / (file.name + ".gz")).write_bytes(packed)
            total_sent += len(packed)
            print(f"  {file.name}: {len(raw) // 1024} KB, sent as {len(packed) // 1024} KB")
        else:
            (PUBLIC / file.name).write_bytes(raw)
            total_sent += len(raw)
    brand = ROOT / "assets/brand"
    for name in ("share_card.jpg", "icon_512.png"):
        shutil.copyfile(brand / name, PUBLIC / name)
    shutil.copyfile(brand / "icon.ico", PUBLIC / "favicon.ico")
    manifest = {
        "name": "Capture the Base", "short_name": "Capture Base", "start_url": "/", "display": "fullscreen",
        "background_color": "#24135f", "theme_color": "#24135f",
        "icons": [{"src": "/icon_512.png", "sizes": "512x512", "type": "image/png"}],
    }
    (PUBLIC / "manifest.webmanifest").write_text(json.dumps(manifest), encoding="utf-8")
    print(f"Total {total_raw // (1024 * 1024)} MB, downloads as {total_sent // (1024 * 1024)} MB")


if __name__ == "__main__":
    make_shell()
    export()
    publish()
