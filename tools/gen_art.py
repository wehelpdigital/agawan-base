"""Draws the game's logo, app icons, the planet's skin and the particle atlas (original art, made here with Pillow).

    python tools/gen_art.py
"""
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_logo  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent

WHITE = (255, 255, 255)
SKY_TOP = (69, 178, 255)
SKY_LOW = (194, 240, 255)
GRASS = (88, 200, 92)
GRASS_DARK = (62, 170, 70)


def vgrad(size, top, low, power=1.0):
    w, h = size
    img = Image.new("RGB", (1, h))
    for y in range(h):
        t = (y / max(h - 1, 1)) ** power
        img.putpixel((0, y), tuple(int(top[i] + (low[i] - top[i]) * t) for i in range(3)))
    return img.resize((w, h))


def star_points(cx, cy, r_out, r_in, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = rot + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def emblem_layer(size):
    """The mark: the little planet with the flag planted on it."""
    img = Image.new("RGBA", (size * 2, size * 2), (0, 0, 0, 0))
    r = int(size * 0.72)
    cx, cy = size, int(size * 1.2)
    gen_logo.globe(img, cx, cy, r)
    gen_logo.team_flag(img, cx + int(r * 0.1), cy - int(r * 0.92), int(r * 0.9), int(r * 0.92))
    return img.resize((size, size), Image.LANCZOS)


def sky_with_hills(size):
    w, h = size
    img = vgrad(size, SKY_TOP, SKY_LOW).convert("RGBA")
    d = ImageDraw.Draw(img)
    for cx, cy, r in [(0.2, 0.2, 0.09), (0.28, 0.21, 0.07), (0.13, 0.22, 0.06), (0.82, 0.13, 0.07), (0.88, 0.14, 0.05), (0.76, 0.15, 0.05)]:
        rr = r * w
        d.ellipse((cx * w - rr, cy * h - rr * 0.6, cx * w + rr, cy * h + rr * 0.6), fill=WHITE + (255,))
    for base, amp, wave, colour in [(0.8, 0.05, 3.1, GRASS), (0.88, 0.05, 4.6, GRASS_DARK)]:
        pts = [(0, h)]
        for x in range(0, w + 8, 8):
            pts.append((x, h * (base - amp * math.sin(x / w * wave * 2))))
        pts.append((w, h))
        d.polygon(pts, fill=colour + (255,))
    return img


def make_icons():
    brand = ROOT / "assets/brand"
    brand.mkdir(parents=True, exist_ok=True)
    full = 1024
    emblem = emblem_layer(full)
    icon = sky_with_hills((full, full))
    icon.alpha_composite(emblem)
    corner = Image.new("L", (full, full), 0)
    ImageDraw.Draw(corner).rounded_rectangle((0, 0, full - 1, full - 1), radius=210, fill=255)
    rounded = Image.new("RGBA", (full, full), (0, 0, 0, 0))
    rounded.paste(icon, (0, 0), corner)
    rounded.resize((256, 256), Image.LANCZOS).save(ROOT / "assets/brand/icon_256.png", optimize=True)
    rounded.resize((512, 512), Image.LANCZOS).save(brand / "icon_512.png", optimize=True)
    icon.convert("RGB").resize((192, 192), Image.LANCZOS).save(brand / "android_192.png", optimize=True)
    # Android adaptive icon: the mark on its own layer, with room for the launcher's mask.
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    small = emblem.resize((300, 300), Image.LANCZOS)
    fg.alpha_composite(small, (66, 66))
    fg.save(brand / "android_fg.png", optimize=True)
    sky_with_hills((432, 432)).convert("RGB").save(brand / "android_bg.png", optimize=True)
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    alpha = small.getchannel("A")
    mono.paste(Image.new("RGBA", small.size, (255, 255, 255, 255)), (66, 66), alpha)
    mono.save(brand / "android_mono.png", optimize=True)
    rounded.resize((256, 256), Image.LANCZOS).save(brand / "icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    emblem.resize((512, 512), Image.LANCZOS).save(brand / "emblem.png", optimize=True)
    # Share card for links.
    card = sky_with_hills((1200, 630))
    logo = Image.open(brand / "logo.png").convert("RGBA")
    logo.thumbnail((860, 540), Image.LANCZOS)
    card.alpha_composite(logo, ((1200 - logo.width) // 2, (630 - logo.height) // 2))
    card.convert("RGB").save(brand / "share_card.jpg", quality=88)


def make_atlas():
    """64 white particle shapes on an 8x8 grid; the game tints them."""
    cell = 128
    scale = 4
    big = cell * scale
    grid = 8
    atlas = Image.new("RGBA", (cell * grid, cell * grid), (0, 0, 0, 0))

    def cell_img(draw_fn, soft=0.0):
        img = Image.new("L", (big, big), 0)
        draw_fn(ImageDraw.Draw(img), big)
        if soft:
            img = img.filter(ImageFilter.GaussianBlur(soft * scale))
        return img.resize((cell, cell), Image.LANCZOS)

    def soft(d, s):
        d.ellipse((s * 0.14, s * 0.14, s * 0.86, s * 0.86), fill=255)

    def star(d, s):
        d.polygon(star_points(s / 2, s * 0.53, s * 0.46, s * 0.2), fill=255)

    def heart(d, s):
        d.ellipse((s * 0.1, s * 0.16, s * 0.54, s * 0.6), fill=255)
        d.ellipse((s * 0.46, s * 0.16, s * 0.9, s * 0.6), fill=255)
        d.polygon([(s * 0.13, s * 0.46), (s * 0.87, s * 0.46), (s * 0.5, s * 0.9)], fill=255)

    def spark(d, s):
        d.polygon(star_points(s / 2, s / 2, s * 0.48, s * 0.09, 4), fill=255)

    def ring(d, s):
        d.ellipse((s * 0.1, s * 0.1, s * 0.9, s * 0.9), fill=255)
        d.ellipse((s * 0.24, s * 0.24, s * 0.76, s * 0.76), fill=70)

    def flame(d, s):
        d.polygon([(s * 0.5, s * 0.04), (s * 0.78, s * 0.46), (s * 0.22, s * 0.46)], fill=255)
        d.ellipse((s * 0.2, s * 0.32, s * 0.8, s * 0.92), fill=255)

    def leaf(d, s):
        d.polygon([(s * 0.18, s * 0.82), (s * 0.12, s * 0.42), (s * 0.34, s * 0.16), (s * 0.84, s * 0.12), (s * 0.82, s * 0.56), (s * 0.58, s * 0.82)], fill=255)

    def note(d, s):
        d.ellipse((s * 0.14, s * 0.62, s * 0.44, s * 0.88), fill=255)
        d.ellipse((s * 0.56, s * 0.54, s * 0.86, s * 0.8), fill=255)
        d.rectangle((s * 0.36, s * 0.16, s * 0.44, s * 0.76), fill=255)
        d.rectangle((s * 0.78, s * 0.1, s * 0.86, s * 0.68), fill=255)
        d.polygon([(s * 0.36, s * 0.16), (s * 0.86, s * 0.1), (s * 0.86, s * 0.26), (s * 0.36, s * 0.32)], fill=255)

    def pixel(d, s):
        d.rectangle((s * 0.18, s * 0.18, s * 0.82, s * 0.82), fill=255)

    def puff(d, s):
        for (x, y, r) in [(0.5, 0.5, 0.3), (0.32, 0.56, 0.2), (0.68, 0.56, 0.2), (0.42, 0.36, 0.2), (0.62, 0.38, 0.18)]:
            d.ellipse((s * (x - r), s * (y - r), s * (x + r), s * (y + r)), fill=255)

    def snow(d, s):
        for i in range(6):
            a = i * math.tau / 6
            x, y = s / 2 + math.cos(a) * s * 0.42, s / 2 + math.sin(a) * s * 0.42
            d.line((s / 2, s / 2, x, y), fill=255, width=int(s * 0.07))
            x2, y2 = s / 2 + math.cos(a) * s * 0.26, s / 2 + math.sin(a) * s * 0.26
            for side in (-0.9, 0.9):
                d.line((x2, y2, x2 + math.cos(a + side) * s * 0.12, y2 + math.sin(a + side) * s * 0.12), fill=255, width=int(s * 0.05))

    def coin(d, s):
        d.ellipse((s * 0.12, s * 0.12, s * 0.88, s * 0.88), fill=255)
        d.ellipse((s * 0.26, s * 0.26, s * 0.74, s * 0.74), fill=190)
        d.rectangle((s * 0.45, s * 0.3, s * 0.55, s * 0.7), fill=255)

    def bolt(d, s):
        d.polygon([(s * 0.58, s * 0.04), (s * 0.2, s * 0.56), (s * 0.46, s * 0.56), (s * 0.38, s * 0.96), (s * 0.8, s * 0.4), (s * 0.52, s * 0.4)], fill=255)

    def petal(d, s):
        for i in range(5):
            a = i * math.tau / 5 - math.pi / 2
            x, y = s / 2 + math.cos(a) * s * 0.24, s / 2 + math.sin(a) * s * 0.24
            d.ellipse((x - s * 0.19, y - s * 0.19, x + s * 0.19, y + s * 0.19), fill=255)
        d.ellipse((s * 0.4, s * 0.4, s * 0.6, s * 0.6), fill=170)

    def drop(d, s):
        d.polygon([(s * 0.5, s * 0.06), (s * 0.76, s * 0.52), (s * 0.24, s * 0.52)], fill=255)
        d.ellipse((s * 0.22, s * 0.36, s * 0.78, s * 0.92), fill=255)

    def confetti(d, s):
        d.polygon([(s * 0.26, s * 0.14), (s * 0.82, s * 0.32), (s * 0.74, s * 0.86), (s * 0.18, s * 0.68)], fill=255)

    def maple(d, s):
        pts = [(0.5, 0.04), (0.58, 0.24), (0.7, 0.18), (0.66, 0.38), (0.9, 0.3), (0.82, 0.46), (0.94, 0.52), (0.7, 0.68), (0.74, 0.76), (0.54, 0.74), (0.54, 0.96),
               (0.46, 0.96), (0.46, 0.74), (0.26, 0.76), (0.3, 0.68), (0.06, 0.52), (0.18, 0.46), (0.1, 0.3), (0.34, 0.38), (0.3, 0.18), (0.42, 0.24)]
        d.polygon([(x * s, y * s) for x, y in pts], fill=255)

    def clover(d, s):
        for x, y in [(0.3, 0.32), (0.7, 0.32), (0.32, 0.66), (0.68, 0.66)]:
            d.ellipse((s * (x - 0.2), s * (y - 0.2), s * (x + 0.2), s * (y + 0.2)), fill=255)
        d.polygon([(s * 0.46, s * 0.5), (s * 0.54, s * 0.5), (s * 0.62, s * 0.96), (s * 0.5, s * 0.96)], fill=255)

    def paw(d, s):
        d.ellipse((s * 0.26, s * 0.46, s * 0.74, s * 0.88), fill=255)
        for x, y, r in [(0.18, 0.42, 0.11), (0.38, 0.22, 0.12), (0.62, 0.22, 0.12), (0.82, 0.42, 0.11)]:
            d.ellipse((s * (x - r), s * (y - r * 1.2), s * (x + r), s * (y + r * 1.2)), fill=255)

    def fish(d, s):
        d.ellipse((s * 0.08, s * 0.24, s * 0.72, s * 0.76), fill=255)
        d.polygon([(s * 0.62, s * 0.5), (s * 0.94, s * 0.22), (s * 0.94, s * 0.78)], fill=255)
        d.ellipse((s * 0.2, s * 0.38, s * 0.3, s * 0.48), fill=60)

    def lantern(d, s):
        d.rectangle((s * 0.36, s * 0.06, s * 0.64, s * 0.14), fill=255)
        d.ellipse((s * 0.14, s * 0.12, s * 0.86, s * 0.78), fill=255)
        d.rectangle((s * 0.36, s * 0.76, s * 0.64, s * 0.84), fill=255)
        d.rectangle((s * 0.46, s * 0.84, s * 0.54, s * 0.98), fill=255)
        for x in (0.32, 0.5, 0.68):
            d.line((s * x, s * 0.16, s * x, s * 0.74), fill=170, width=int(s * 0.03))

    def skull(d, s):
        d.ellipse((s * 0.14, s * 0.08, s * 0.86, s * 0.72), fill=255)
        d.rounded_rectangle((s * 0.3, s * 0.58, s * 0.7, s * 0.92), radius=int(s * 0.06), fill=255)
        d.ellipse((s * 0.26, s * 0.3, s * 0.44, s * 0.5), fill=40)
        d.ellipse((s * 0.56, s * 0.3, s * 0.74, s * 0.5), fill=40)
        d.polygon([(s * 0.5, s * 0.52), (s * 0.44, s * 0.62), (s * 0.56, s * 0.62)], fill=40)
        for x in (0.42, 0.5, 0.58):
            d.line((s * x, s * 0.72, s * x, s * 0.92), fill=60, width=int(s * 0.025))

    def smile(d, s):
        d.ellipse((s * 0.08, s * 0.08, s * 0.92, s * 0.92), fill=255)
        d.ellipse((s * 0.3, s * 0.28, s * 0.42, s * 0.46), fill=40)
        d.ellipse((s * 0.58, s * 0.28, s * 0.7, s * 0.46), fill=40)
        d.chord((s * 0.24, s * 0.3, s * 0.76, s * 0.8), 10, 170, fill=40)

    def crown(d, s):
        d.polygon([(s * 0.08, s * 0.8), (s * 0.08, s * 0.28), (s * 0.3, s * 0.5), (s * 0.5, s * 0.14), (s * 0.7, s * 0.5), (s * 0.92, s * 0.28), (s * 0.92, s * 0.8)], fill=255)
        for x, y in [(0.08, 0.26), (0.5, 0.12), (0.92, 0.26)]:
            d.ellipse((s * (x - 0.06), s * (y - 0.06), s * (x + 0.06), s * (y + 0.06)), fill=255)

    def diamond(d, s):
        d.polygon([(s * 0.26, s * 0.14), (s * 0.74, s * 0.14), (s * 0.94, s * 0.4), (s * 0.5, s * 0.94), (s * 0.06, s * 0.4)], fill=255)
        d.line((s * 0.06, s * 0.4, s * 0.94, s * 0.4), fill=180, width=int(s * 0.03))
        d.line((s * 0.34, s * 0.4, s * 0.5, s * 0.94), fill=180, width=int(s * 0.03))
        d.line((s * 0.66, s * 0.4, s * 0.5, s * 0.94), fill=180, width=int(s * 0.03))

    def moon(d, s):
        d.ellipse((s * 0.1, s * 0.08, s * 0.9, s * 0.92), fill=255)
        d.ellipse((s * 0.36, s * 0.02, s * 1.02, s * 0.74), fill=0)

    def sun(d, s):
        for i in range(10):
            a = i * math.tau / 10
            x, y = s / 2 + math.cos(a) * s * 0.46, s / 2 + math.sin(a) * s * 0.46
            d.line((s / 2, s / 2, x, y), fill=255, width=int(s * 0.09))
        d.ellipse((s * 0.24, s * 0.24, s * 0.76, s * 0.76), fill=255)

    def pizza(d, s):
        d.polygon([(s * 0.5, s * 0.96), (s * 0.08, s * 0.2), (s * 0.92, s * 0.2)], fill=255)
        d.chord((s * 0.04, s * 0.06, s * 0.96, s * 0.4), 180, 360, fill=255)
        for x, y in [(0.38, 0.34), (0.62, 0.36), (0.5, 0.58)]:
            d.ellipse((s * (x - 0.08), s * (y - 0.08), s * (x + 0.08), s * (y + 0.08)), fill=120)

    def banana(d, s):
        pts = []
        for i in range(21):
            a = math.pi * (0.1 + 0.75 * i / 20)
            pts.append((s * (0.5 + math.cos(a) * 0.46), s * (0.2 + math.sin(a) * 0.7)))
        for i in range(20, -1, -1):
            a = math.pi * (0.1 + 0.75 * i / 20)
            pts.append((s * (0.56 + math.cos(a) * 0.26), s * (0.2 + math.sin(a) * 0.44)))
        d.polygon(pts, fill=255)

    def feather(d, s):
        d.polygon([(s * 0.76, s * 0.04), (s * 0.92, s * 0.26), (s * 0.7, s * 0.6), (s * 0.34, s * 0.82), (s * 0.2, s * 0.68), (s * 0.42, s * 0.3)], fill=255)
        d.line((s * 0.08, s * 0.96, s * 0.76, s * 0.16), fill=170, width=int(s * 0.03))
        d.line((s * 0.08, s * 0.96, s * 0.3, s * 0.72), fill=255, width=int(s * 0.04))

    def swirl(d, s):
        pts = []
        for i in range(60):
            t = i / 59
            a = t * math.tau * 2.2
            r = 0.05 + t * 0.4
            pts.append((s * (0.5 + math.cos(a) * r), s * (0.5 + math.sin(a) * r)))
        d.line(pts, fill=255, width=int(s * 0.09), joint="curve")

    def streak(d, s):
        d.rounded_rectangle((s * 0.42, s * 0.02, s * 0.58, s * 0.98), radius=int(s * 0.08), fill=255)

    def cherry(d, s):
        for i in range(5):
            a = i * math.tau / 5 - math.pi / 2
            x, y = s / 2 + math.cos(a) * s * 0.27, s / 2 + math.sin(a) * s * 0.27
            d.ellipse((x - s * 0.17, y - s * 0.2, x + s * 0.17, y + s * 0.2), fill=255)
            nx, ny = s / 2 + math.cos(a) * s * 0.47, s / 2 + math.sin(a) * s * 0.47
            d.ellipse((nx - s * 0.04, ny - s * 0.04, nx + s * 0.04, ny + s * 0.04), fill=0)
        d.ellipse((s * 0.42, s * 0.42, s * 0.58, s * 0.58), fill=150)

    def tulip(d, s):
        d.polygon([(s * 0.14, s * 0.1), (s * 0.34, s * 0.3), (s * 0.5, s * 0.06), (s * 0.66, s * 0.3), (s * 0.86, s * 0.1), (s * 0.86, s * 0.58), (s * 0.5, s * 0.74), (s * 0.14, s * 0.58)], fill=255)
        d.ellipse((s * 0.14, s * 0.36, s * 0.86, s * 0.76), fill=255)
        d.rectangle((s * 0.46, s * 0.72, s * 0.54, s * 0.98), fill=200)

    def zzz(d, s):
        for x, y, z in [(0.08, 0.52, 0.42), (0.52, 0.16, 0.3)]:
            w = z
            d.line([(s * x, s * y), (s * (x + w), s * y), (s * x, s * (y + w)), (s * (x + w), s * (y + w))], fill=255, width=int(s * 0.1), joint="curve")

    def bee(d, s):
        d.ellipse((s * 0.16, s * 0.34, s * 0.84, s * 0.84), fill=255)
        for x in (0.42, 0.62):
            d.rectangle((s * x, s * 0.36, s * (x + 0.08), s * 0.82), fill=50)
        d.ellipse((s * 0.26, s * 0.08, s * 0.56, s * 0.42), fill=210)
        d.ellipse((s * 0.5, s * 0.1, s * 0.8, s * 0.42), fill=210)

    def bamboo(d, s):
        d.rounded_rectangle((s * 0.4, s * 0.04, s * 0.58, s * 0.96), radius=int(s * 0.05), fill=255)
        for y in (0.3, 0.62):
            d.rectangle((s * 0.36, s * y, s * 0.62, s * (y + 0.045)), fill=150)
        d.polygon([(s * 0.58, s * 0.3), (s * 0.96, s * 0.08), (s * 0.82, s * 0.32)], fill=255)
        d.polygon([(s * 0.4, s * 0.62), (s * 0.04, s * 0.42), (s * 0.16, s * 0.68)], fill=255)

    def sword(d, s):
        d.polygon([(s * 0.5, s * 0.02), (s * 0.59, s * 0.14), (s * 0.59, s * 0.66), (s * 0.41, s * 0.66), (s * 0.41, s * 0.14)], fill=255)
        d.line((s * 0.5, s * 0.1, s * 0.5, s * 0.64), fill=170, width=int(s * 0.025))
        d.rounded_rectangle((s * 0.24, s * 0.65, s * 0.76, s * 0.73), radius=int(s * 0.03), fill=255)
        d.rectangle((s * 0.45, s * 0.72, s * 0.55, s * 0.9), fill=255)
        d.ellipse((s * 0.42, s * 0.87, s * 0.58, s * 0.99), fill=255)

    def shield(d, s):
        d.polygon([(s * 0.12, s * 0.12), (s * 0.88, s * 0.12), (s * 0.88, s * 0.52), (s * 0.74, s * 0.76), (s * 0.5, s * 0.96), (s * 0.26, s * 0.76), (s * 0.12, s * 0.52)], fill=255)
        d.polygon([(s * 0.12, s * 0.56), (s * 0.5, s * 0.26), (s * 0.88, s * 0.56), (s * 0.88, s * 0.44), (s * 0.5, s * 0.14), (s * 0.12, s * 0.44)], fill=150)

    def shuriken(d, s):
        d.polygon(star_points(s / 2, s / 2, s * 0.49, s * 0.15, 4), fill=255)
        d.ellipse((s * 0.42, s * 0.42, s * 0.58, s * 0.58), fill=40)

    def koi(d, s):
        d.ellipse((s * 0.26, s * 0.06, s * 0.74, s * 0.66), fill=255)
        d.polygon([(s * 0.4, s * 0.6), (s * 0.6, s * 0.6), (s * 0.54, s * 0.78), (s * 0.82, s * 0.96), (s * 0.5, s * 0.86), (s * 0.18, s * 0.96), (s * 0.46, s * 0.78)], fill=255)
        d.polygon([(s * 0.28, s * 0.3), (s * 0.08, s * 0.44), (s * 0.3, s * 0.46)], fill=255)
        d.polygon([(s * 0.72, s * 0.3), (s * 0.92, s * 0.44), (s * 0.7, s * 0.46)], fill=255)
        d.ellipse((s * 0.36, s * 0.3, s * 0.64, s * 0.5), fill=150)
        for x in (0.38, 0.62):
            d.ellipse((s * (x - 0.03), s * 0.14, s * (x + 0.03), s * 0.2), fill=40)

    def dumpling(d, s):
        d.chord((s * 0.06, s * 0.2, s * 0.94, s * 1.02), 180, 360, fill=255)
        d.rectangle((s * 0.08, s * 0.6, s * 0.92, s * 0.72), fill=255)
        for x in (0.3, 0.44, 0.58, 0.72):
            d.line((s * x, s * 0.26, s * 0.5, s * 0.56), fill=150, width=int(s * 0.03))

    def sushi(d, s):
        d.rounded_rectangle((s * 0.1, s * 0.44, s * 0.9, s * 0.84), radius=int(s * 0.12), fill=210)
        d.rounded_rectangle((s * 0.06, s * 0.24, s * 0.94, s * 0.56), radius=int(s * 0.14), fill=255)
        for x in (0.26, 0.44, 0.62, 0.8):
            d.line((s * x, s * 0.26, s * (x - 0.06), s * 0.54), fill=170, width=int(s * 0.03))
        d.rectangle((s * 0.42, s * 0.24, s * 0.58, s * 0.84), fill=70)

    def taco(d, s):
        for i in range(7):
            x = 0.16 + i * 0.113
            d.ellipse((s * (x - 0.09), s * 0.18, s * (x + 0.09), s * 0.38), fill=170)
        d.pieslice((s * 0.06, s * 0.22, s * 0.94, s * 1.1), 180, 360, fill=255)
        for x, y in [(0.32, 0.5), (0.52, 0.42), (0.68, 0.56)]:
            d.ellipse((s * (x - 0.03), s * (y - 0.03), s * (x + 0.03), s * (y + 0.03)), fill=170)

    def croissant(d, s):
        pts_out, pts_in = [], []
        for i in range(25):
            a = math.pi * (1.05 - 1.1 * i / 24)
            pts_out.append((s * (0.5 + math.cos(a) * 0.46), s * (0.72 - math.sin(a) * 0.56)))
            pts_in.append((s * (0.5 + math.cos(a) * 0.24), s * (0.8 - math.sin(a) * 0.26)))
        d.polygon(pts_out + pts_in[::-1], fill=255)
        for f in (0.28, 0.42, 0.58, 0.72):
            a = math.pi * (1.05 - 1.1 * f)
            d.line((s * (0.5 + math.cos(a) * 0.46), s * (0.72 - math.sin(a) * 0.56), s * (0.5 + math.cos(a) * 0.24), s * (0.8 - math.sin(a) * 0.26)), fill=160, width=int(s * 0.03))

    def donut(d, s):
        d.ellipse((s * 0.06, s * 0.06, s * 0.94, s * 0.94), fill=255)
        d.ellipse((s * 0.36, s * 0.36, s * 0.64, s * 0.64), fill=0)
        for x, y in [(0.24, 0.3), (0.5, 0.2), (0.74, 0.32), (0.8, 0.58), (0.58, 0.8), (0.3, 0.76), (0.18, 0.54)]:
            d.ellipse((s * (x - 0.03), s * (y - 0.04), s * (x + 0.03), s * (y + 0.04)), fill=150)

    def teacup(d, s):
        d.chord((s * 0.08, s * 0.1, s * 0.78, s * 0.86), 0, 180, fill=255)
        d.rectangle((s * 0.08, s * 0.44, s * 0.78, s * 0.5), fill=255)
        d.ellipse((s * 0.68, s * 0.44, s * 0.96, s * 0.74), fill=255)
        d.ellipse((s * 0.76, s * 0.52, s * 0.88, s * 0.66), fill=0)
        d.rounded_rectangle((s * 0.08, s * 0.84, s * 0.78, s * 0.92), radius=int(s * 0.03), fill=255)
        for x in (0.32, 0.54):
            d.arc((s * (x - 0.08), s * 0.04, s * (x + 0.08), s * 0.26), 100, 300, fill=255, width=int(s * 0.04))

    def hibiscus(d, s):
        for i in range(5):
            a = i * math.tau / 5 - math.pi / 2
            x, y = s / 2 + math.cos(a) * s * 0.26, s / 2 + math.sin(a) * s * 0.26
            d.ellipse((x - s * 0.22, y - s * 0.22, x + s * 0.22, y + s * 0.22), fill=255)
        d.line((s * 0.5, s * 0.5, s * 0.78, s * 0.22), fill=120, width=int(s * 0.05))
        d.ellipse((s * 0.74, s * 0.16, s * 0.84, s * 0.26), fill=120)
        d.ellipse((s * 0.42, s * 0.42, s * 0.58, s * 0.58), fill=150)

    def rose(d, s):
        d.ellipse((s * 0.1, s * 0.08, s * 0.9, s * 0.88), fill=255)
        for box, start, end in [((0.2, 0.18, 0.8, 0.78), 200, 420), ((0.3, 0.26, 0.72, 0.68), 20, 250), ((0.4, 0.36, 0.62, 0.58), 180, 470)]:
            d.arc((s * box[0], s * box[1], s * box[2], s * box[3]), start, end, fill=130, width=int(s * 0.035))
        d.polygon([(s * 0.22, s * 0.8), (s * 0.02, s * 0.98), (s * 0.38, s * 0.92)], fill=200)
        d.polygon([(s * 0.78, s * 0.8), (s * 0.98, s * 0.98), (s * 0.62, s * 0.92)], fill=200)

    def palm(d, s):
        d.line((s * 0.52, s * 0.98, s * 0.46, s * 0.36), fill=200, width=int(s * 0.07))
        for a0, a1 in [(-160, -110), (-130, -70), (-95, -35), (-60, -5), (-20, 25), (-200, -150)]:
            pts = [(s * 0.46, s * 0.36)]
            for t in range(9):
                f = t / 8
                a = math.radians(a0 + (a1 - a0) * f)
                pts.append((s * (0.46 + math.cos(a) * 0.46 * (0.6 + 0.4 * f)), s * (0.36 + math.sin(a) * 0.3 + f * f * 0.2)))
            d.polygon(pts, fill=255)

    def cactus(d, s):
        d.rounded_rectangle((s * 0.4, s * 0.08, s * 0.6, s * 0.96), radius=int(s * 0.1), fill=255)
        d.rounded_rectangle((s * 0.14, s * 0.3, s * 0.3, s * 0.62), radius=int(s * 0.08), fill=255)
        d.rectangle((s * 0.2, s * 0.52, s * 0.42, s * 0.62), fill=255)
        d.rounded_rectangle((s * 0.7, s * 0.2, s * 0.86, s * 0.52), radius=int(s * 0.08), fill=255)
        d.rectangle((s * 0.58, s * 0.42, s * 0.8, s * 0.52), fill=255)
        d.line((s * 0.5, s * 0.16, s * 0.5, s * 0.9), fill=170, width=int(s * 0.03))

    def mushroom(d, s):
        d.chord((s * 0.06, s * 0.06, s * 0.94, s * 0.9), 180, 360, fill=255)
        d.rounded_rectangle((s * 0.34, s * 0.46, s * 0.66, s * 0.96), radius=int(s * 0.1), fill=205)
        for x, y, r in [(0.3, 0.32, 0.08), (0.56, 0.2, 0.08), (0.74, 0.36, 0.06)]:
            d.ellipse((s * (x - r), s * (y - r), s * (x + r), s * (y + r)), fill=120)

    def pumpkin(d, s):
        for x, w in [(0.22, 0.28), (0.78, 0.28), (0.35, 0.32), (0.65, 0.32), (0.5, 0.34)]:
            d.ellipse((s * (x - w / 2), s * 0.22, s * (x + w / 2), s * 0.94), fill=255)
        d.rectangle((s * 0.45, s * 0.06, s * 0.57, s * 0.26), fill=200)
        d.polygon([(s * 0.3, s * 0.44), (s * 0.42, s * 0.44), (s * 0.36, s * 0.56)], fill=60)
        d.polygon([(s * 0.58, s * 0.44), (s * 0.7, s * 0.44), (s * 0.64, s * 0.56)], fill=60)
        d.chord((s * 0.3, s * 0.48, s * 0.7, s * 0.82), 10, 170, fill=60)

    def bat(d, s):
        d.ellipse((s * 0.38, s * 0.34, s * 0.62, s * 0.74), fill=255)
        d.polygon([(s * 0.4, s * 0.38), (s * 0.42, s * 0.22), (s * 0.48, s * 0.34)], fill=255)
        d.polygon([(s * 0.6, s * 0.38), (s * 0.58, s * 0.22), (s * 0.52, s * 0.34)], fill=255)
        d.polygon([(s * 0.4, s * 0.42), (s * 0.04, s * 0.26), (s * 0.1, s * 0.56), (s * 0.2, s * 0.5), (s * 0.28, s * 0.66), (s * 0.42, s * 0.6)], fill=255)
        d.polygon([(s * 0.6, s * 0.42), (s * 0.96, s * 0.26), (s * 0.9, s * 0.56), (s * 0.8, s * 0.5), (s * 0.72, s * 0.66), (s * 0.58, s * 0.6)], fill=255)

    def ghost(d, s):
        d.chord((s * 0.14, s * 0.06, s * 0.86, s * 0.86), 180, 360, fill=255)
        d.polygon([(s * 0.14, s * 0.44), (s * 0.86, s * 0.44), (s * 0.86, s * 0.94), (s * 0.68, s * 0.8), (s * 0.5, s * 0.94), (s * 0.32, s * 0.8), (s * 0.14, s * 0.94)], fill=255)
        for x in (0.36, 0.64):
            d.ellipse((s * (x - 0.07), s * 0.3, s * (x + 0.07), s * 0.48), fill=40)

    def butterfly(d, s):
        d.ellipse((s * 0.06, s * 0.1, s * 0.48, s * 0.56), fill=255)
        d.ellipse((s * 0.52, s * 0.1, s * 0.94, s * 0.56), fill=255)
        d.ellipse((s * 0.14, s * 0.5, s * 0.46, s * 0.88), fill=225)
        d.ellipse((s * 0.54, s * 0.5, s * 0.86, s * 0.88), fill=225)
        d.rounded_rectangle((s * 0.46, s * 0.18, s * 0.54, s * 0.86), radius=int(s * 0.04), fill=70)
        for x in (0.22, 0.78):
            d.ellipse((s * (x - 0.06), s * 0.26, s * (x + 0.06), s * 0.38), fill=140)

    def bubble(d, s):
        d.ellipse((s * 0.08, s * 0.08, s * 0.92, s * 0.92), fill=120)
        d.ellipse((s * 0.14, s * 0.14, s * 0.86, s * 0.86), fill=70)
        d.ellipse((s * 0.26, s * 0.22, s * 0.46, s * 0.42), fill=255)
        d.ellipse((s * 0.54, s * 0.58, s * 0.62, s * 0.66), fill=210)

    def rainbow(d, s):
        for r, v in [(0.46, 255), (0.36, 200), (0.26, 255)]:
            d.chord((s * (0.5 - r), s * (0.72 - r), s * (0.5 + r), s * (0.72 + r)), 180, 360, fill=v)
        d.chord((s * 0.34, s * 0.56, s * 0.66, s * 0.88), 180, 360, fill=0)
        for x in (0.14, 0.86):
            d.ellipse((s * (x - 0.14), s * 0.6, s * (x + 0.14), s * 0.84), fill=255)

    def cloud(d, s):
        for x, y, r in [(0.28, 0.6, 0.2), (0.5, 0.46, 0.27), (0.74, 0.58, 0.22)]:
            d.ellipse((s * (x - r), s * (y - r), s * (x + r), s * (y + r)), fill=255)
        d.rounded_rectangle((s * 0.1, s * 0.56, s * 0.92, s * 0.8), radius=int(s * 0.12), fill=255)

    def anchor(d, s):
        d.ellipse((s * 0.4, s * 0.04, s * 0.6, s * 0.24), fill=255)
        d.ellipse((s * 0.46, s * 0.1, s * 0.54, s * 0.18), fill=0)
        d.rectangle((s * 0.45, s * 0.22, s * 0.55, s * 0.88), fill=255)
        d.rectangle((s * 0.28, s * 0.3, s * 0.72, s * 0.38), fill=255)
        d.arc((s * 0.1, s * 0.34, s * 0.9, s * 0.94), 10, 170, fill=255, width=int(s * 0.1))
        d.polygon([(s * 0.04, s * 0.62), (s * 0.24, s * 0.62), (s * 0.12, s * 0.8)], fill=255)
        d.polygon([(s * 0.96, s * 0.62), (s * 0.76, s * 0.62), (s * 0.88, s * 0.8)], fill=255)

    def rocket(d, s):
        d.ellipse((s * 0.3, s * 0.04, s * 0.7, s * 0.84), fill=255)
        d.polygon([(s * 0.32, s * 0.5), (s * 0.12, s * 0.8), (s * 0.34, s * 0.74)], fill=225)
        d.polygon([(s * 0.68, s * 0.5), (s * 0.88, s * 0.8), (s * 0.66, s * 0.74)], fill=225)
        d.polygon([(s * 0.38, s * 0.82), (s * 0.62, s * 0.82), (s * 0.5, s * 1.0)], fill=170)
        d.ellipse((s * 0.41, s * 0.26, s * 0.59, s * 0.44), fill=70)

    def planet(d, s):
        d.ellipse((s * 0.24, s * 0.24, s * 0.76, s * 0.76), fill=255)
        d.arc((s * 0.02, s * 0.32, s * 0.98, s * 0.68), 340, 200, fill=190, width=int(s * 0.06))
        d.line((s * 0.3, s * 0.42, s * 0.7, s * 0.42), fill=200, width=int(s * 0.03))

    def umbrella(d, s):
        d.pieslice((s * 0.04, s * 0.08, s * 0.96, s * 0.92), 180, 360, fill=255)
        for x in (0.2, 0.5, 0.8):
            d.line((s * 0.5, s * 0.08, s * x, s * 0.5), fill=170, width=int(s * 0.03))
        d.rectangle((s * 0.47, s * 0.48, s * 0.53, s * 0.86), fill=255)
        d.arc((s * 0.33, s * 0.74, s * 0.53, s * 0.98), 0, 180, fill=255, width=int(s * 0.055))

    def dice(d, s):
        d.rounded_rectangle((s * 0.12, s * 0.12, s * 0.88, s * 0.88), radius=int(s * 0.16), fill=255)
        for x, y in [(0.32, 0.32), (0.68, 0.32), (0.5, 0.5), (0.32, 0.68), (0.68, 0.68)]:
            d.ellipse((s * (x - 0.07), s * (y - 0.07), s * (x + 0.07), s * (y + 0.07)), fill=50)

    shapes = [(soft, 3.5), star, heart, spark, ring, flame, leaf, note, pixel, (puff, 1.2), snow, coin, bolt, petal, drop, confetti,
              maple, clover, paw, fish, lantern, skull, smile, crown, diamond, moon, sun, pizza, banana, feather, swirl, (streak, 0.6), cherry, tulip, zzz, bee,
              bamboo, sword, shield, shuriken, koi, dumpling, sushi, taco, croissant, donut, teacup, hibiscus, rose, palm, cactus, mushroom, pumpkin, bat, ghost,
              butterfly, bubble, rainbow, cloud, anchor, rocket, planet, umbrella, dice]
    for i, shape in enumerate(shapes):
        fn, blur = shape if isinstance(shape, tuple) else (shape, 0.0)
        mask = cell_img(fn, blur)
        x, y = (i % grid) * cell, (i // grid) * cell
        # An ink edge around each shape, so particles read on any floor.
        edge = mask.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(1.0)) if not blur else None
        tile = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
        if edge is not None:
            tile.paste(Image.new("RGBA", (cell, cell), (50, 40, 110, 255)), (0, 0), edge)
        tile.paste(Image.new("RGBA", (cell, cell), (255, 255, 255, 255)), (0, 0), mask)
        atlas.alpha_composite(tile, (x, y))
    out = ROOT / "assets/fx"
    out.mkdir(parents=True, exist_ok=True)
    atlas.save(out / "atlas.png", optimize=True)


def main():
    random.seed(7)
    brand = ROOT / "assets/brand"
    brand.mkdir(parents=True, exist_ok=True)
    make_atlas()
    gen_logo.make_logo(brand / "logo.png")
    gen_logo.world_map(1024).save(brand / "world_map.png", optimize=True)
    make_icons()
    print("art done")


if __name__ == "__main__":
    main()
