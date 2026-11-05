"""Draws the game's logo, app icons and particle atlas (original art, made here with Pillow).

    python tools/gen_art.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TITAN = str(ROOT / "assets/fonts/TitanOne-Regular.ttf")

INK = (36, 19, 95)
INK_DARK = (22, 10, 66)
SUN_TOP = (255, 236, 110)
SUN_LOW = (255, 150, 30)
WAVE_TOP = (120, 245, 255)
WAVE_LOW = (30, 130, 255)
WHITE = (255, 255, 255)
CORAL = (255, 79, 107)
MINT = (53, 208, 127)


def vgrad(size, top, low, power=1.0):
    w, h = size
    img = Image.new("RGB", (1, h))
    for y in range(h):
        t = (y / max(h - 1, 1)) ** power
        img.putpixel((0, y), tuple(int(top[i] + (low[i] - top[i]) * t) for i in range(3)))
    return img.resize((w, h))


def letter_mask(ch, font, stroke=0):
    pad = 40 + stroke
    box = font.getbbox(ch, stroke_width=stroke)
    w, h = box[2] - box[0] + pad * 2, box[3] - box[1] + pad * 2
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.text((pad - box[0], pad - box[1]), ch, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
    return mask


def paste_masked(canvas, color_or_img, mask, xy):
    if isinstance(color_or_img, tuple):
        layer = Image.new("RGBA", mask.size, color_or_img + (255,))
    else:
        layer = color_or_img.convert("RGBA").resize(mask.size)
    canvas.paste(layer, xy, mask)


def word(canvas, text, font, center, tilts, top, low, spacing=-6, base_shift=None, extrude=24, outline=26):
    """Chunky letters: a deep extruded shadow, a thick ink outline, a gradient face with a shine band."""
    widths = []
    for ch in text:
        b = font.getbbox(ch)
        widths.append(b[2] - b[0])
    total = sum(widths) + spacing * (len(text) - 1)
    x = center[0] - total / 2
    placed = []
    for i, ch in enumerate(text):
        tilt = tilts[i % len(tilts)]
        dy = base_shift[i % len(base_shift)] if base_shift else 0
        placed.append((ch, x, center[1] + dy, tilt, widths[i]))
        x += widths[i] + spacing
    # Everything is drawn twice over: first all the outlines, so letters can overlap cleanly.
    for ch, lx, ly, tilt, w in placed:
        mask = letter_mask(ch, font, outline).rotate(tilt, resample=Image.BICUBIC, expand=True)
        for step in range(extrude, 0, -2):
            canvas.paste(Image.new("RGBA", mask.size, INK_DARK + (255,)),
                         (int(lx + w / 2 - mask.width / 2), int(ly - mask.height / 2 + step)), mask)
        canvas.paste(Image.new("RGBA", mask.size, INK + (255,)), (int(lx + w / 2 - mask.width / 2), int(ly - mask.height / 2)), mask)
    for ch, lx, ly, tilt, w in placed:
        base = letter_mask(ch, font, 0)
        face = vgrad(base.size, top, low, 1.1).convert("RGBA")
        # A shine across the upper part of the letter.
        shine = Image.new("L", base.size, 0)
        ImageDraw.Draw(shine).rectangle((0, 0, base.width, int(base.height * 0.47)), fill=70)
        face = Image.composite(Image.new("RGBA", base.size, WHITE + (255,)), face, shine)
        # An inner rim along the bottom edge.
        low_rim = ImageChops.subtract(base, ImageChops.offset(base, 0, -6))
        face = Image.composite(Image.new("RGBA", base.size, tuple(int(c * 0.72) for c in low) + (255,)), face, low_rim)
        face.putalpha(base)
        rotated = face.rotate(tilt, resample=Image.BICUBIC, expand=True)
        canvas.alpha_composite(rotated, (max(int(lx + w / 2 - rotated.width / 2), 0), max(int(ly - rotated.height / 2), 0)))


def star_points(cx, cy, r_out, r_in, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = r_out if i % 2 == 0 else r_in
        a = rot + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def emblem_layer(size):
    """The mark: two chunky flags crossed behind a base pad with a star, half sun, half wave."""
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    r = s * 0.42
    # Rays behind everything.
    for i in range(12):
        a0 = i * math.tau / 12 + 0.13
        a1 = a0 + math.tau / 24
        d.polygon([(c, c), (c + math.cos(a0) * r * 1.16, c + math.sin(a0) * r * 1.16), (c + math.cos(a1) * r * 1.16, c + math.sin(a1) * r * 1.16)],
                  fill=(255, 210, 63, 255))
    d.ellipse((c - r * 1.02, c - r * 1.02, c + r * 1.02, c + r * 1.02), fill=INK + (255,))
    # Sun half and wave half.
    inner = r * 0.9
    half = Image.new("L", (s, s), 0)
    ImageDraw.Draw(half).ellipse((c - inner, c - inner, c + inner, c + inner), fill=255)
    left = vgrad((s, s), SUN_TOP, SUN_LOW).convert("RGBA")
    right = vgrad((s, s), WAVE_TOP, WAVE_LOW).convert("RGBA")
    split = Image.new("L", (s, s), 0)
    ImageDraw.Draw(split).polygon([(0, 0), (s * 0.58, 0), (s * 0.42, s), (0, s)], fill=255)
    mix = Image.composite(left, right, split)
    img.paste(mix, (0, 0), half)
    d = ImageDraw.Draw(img)
    # The zig-zag between the halves.
    d.line([(s * 0.58, c - inner), (s * 0.49, c - inner * 0.28), (s * 0.54, c - inner * 0.2), (s * 0.42, c + inner)], fill=INK + (255,), width=int(s * 0.024), joint="curve")
    # Flag on a pole, planted on the base.
    pole_x = c - r * 0.04
    d.rounded_rectangle((pole_x - s * 0.028, c - r * 0.74, pole_x + s * 0.028, c + r * 0.56), radius=int(s * 0.02), fill=INK + (255,))
    d.rounded_rectangle((pole_x - s * 0.013, c - r * 0.72, pole_x + s * 0.013, c + r * 0.54), radius=int(s * 0.01), fill=WHITE + (255,))
    d.polygon([(pole_x + s * 0.02, c - r * 0.78), (pole_x + r * 0.76, c - r * 0.44), (pole_x + s * 0.02, c - r * 0.06)], fill=INK + (255,))
    d.polygon([(pole_x + s * 0.045, c - r * 0.66), (pole_x + r * 0.58, c - r * 0.43), (pole_x + s * 0.045, c - r * 0.19)], fill=CORAL + (255,))
    pts = star_points(pole_x + r * 0.2, c - r * 0.43, r * 0.13, r * 0.06)
    d.polygon(pts, fill=WHITE + (255,))
    # The pad.
    d.ellipse((c - r * 0.62, c + r * 0.34, c + r * 0.62, c + r * 0.78), fill=INK + (255,))
    d.ellipse((c - r * 0.54, c + r * 0.38, c + r * 0.54, c + r * 0.7), fill=(255, 255, 255, 255))
    d.ellipse((c - r * 0.38, c + r * 0.44, c + r * 0.38, c + r * 0.64), fill=MINT + (255,))
    return img


def make_logo(path, width=1600):
    h = int(width * 0.62)
    canvas = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    big = ImageFont.truetype(TITAN, int(width * 0.2))
    huge = ImageFont.truetype(TITAN, int(width * 0.285))
    small = ImageFont.truetype(TITAN, int(width * 0.062))
    word(canvas, "CAPTURE", big, (width * 0.5, h * 0.27), [3, -2, 2, -3, 2, -2, 3], SUN_TOP, SUN_LOW,
         spacing=int(-width * 0.002), base_shift=[10, -6, 8, -4, 6, -8, 8], extrude=int(width * 0.018), outline=int(width * 0.016))
    word(canvas, "BASE", huge, (width * 0.5, h * 0.71), [-3, 2, -2, 3], WAVE_TOP, WAVE_LOW,
         spacing=int(width * 0.008), base_shift=[-6, 8, -8, 6], extrude=int(width * 0.022), outline=int(width * 0.018))
    # "THE" on a ribbon between the words.
    d = ImageDraw.Draw(canvas)
    rx, ry = width * 0.5, h * 0.475
    rw, rh = width * 0.105, width * 0.05
    lean = width * 0.008
    d.polygon([(rx - rw * 1.08, ry - rh * 1.14 + lean), (rx + rw * 1.08, ry - rh * 1.14 - lean), (rx + rw * 1.08, ry + rh * 1.2 - lean), (rx - rw * 1.08, ry + rh * 1.2 + lean)], fill=INK + (255,))
    d.polygon([(rx - rw, ry - rh * 0.86 + lean), (rx + rw, ry - rh * 0.86 - lean), (rx + rw, ry + rh * 0.92 - lean), (rx - rw, ry + rh * 0.92 + lean)], fill=CORAL + (255,))
    mask = letter_mask("THE", small, 0).rotate(2, resample=Image.BICUBIC, expand=True)
    canvas.paste(Image.new("RGBA", mask.size, WHITE + (255,)), (int(rx - mask.width / 2), int(ry - mask.height / 2)), mask)
    # Sparkles.
    for (x, y, r) in [(0.075, 0.13, 0.024), (0.93, 0.21, 0.03), (0.06, 0.72, 0.018), (0.94, 0.78, 0.022)]:
        pts = star_points(width * x, h * y, width * r, width * r * 0.3, 4)
        d.polygon([(a + 3, b + 6) for a, b in pts], fill=INK + (255,))
        d.polygon(pts, fill=WHITE + (255,))
    canvas = canvas.crop(canvas.getbbox())
    canvas.save(path, optimize=True)


def make_icons():
    brand = ROOT / "assets/brand"
    brand.mkdir(parents=True, exist_ok=True)
    full = 1024
    bg = vgrad((full, full), (112, 62, 230), (46, 22, 130)).convert("RGBA")
    emblem = emblem_layer(full)
    icon = bg.copy()
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
    vgrad((432, 432), (112, 62, 230), (46, 22, 130)).save(brand / "android_bg.png", optimize=True)
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    alpha = small.getchannel("A")
    mono.paste(Image.new("RGBA", small.size, (255, 255, 255, 255)), (66, 66), alpha)
    mono.save(brand / "android_mono.png", optimize=True)
    rounded.resize((256, 256), Image.LANCZOS).save(brand / "icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    emblem.resize((512, 512), Image.LANCZOS).save(brand / "emblem.png", optimize=True)
    # Share card for links.
    card = vgrad((1200, 630), (112, 62, 230), (36, 19, 95)).convert("RGBA")
    d = ImageDraw.Draw(card)
    for i in range(16):
        a0 = i * math.tau / 16
        d.polygon([(600, 315), (600 + math.cos(a0) * 900, 315 + math.sin(a0) * 900), (600 + math.cos(a0 + 0.2) * 900, 315 + math.sin(a0 + 0.2) * 900)], fill=(130, 80, 240, 255))
    logo = Image.open(brand / "logo.png").convert("RGBA")
    logo.thumbnail((900, 520), Image.LANCZOS)
    card.alpha_composite(logo, ((1200 - logo.width) // 2, (630 - logo.height) // 2))
    card.convert("RGB").save(brand / "share_card.jpg", quality=88)


def make_atlas():
    """16 white particle shapes on a 4x4 grid; the game tints them."""
    cell = 128
    scale = 4
    big = cell * scale
    atlas = Image.new("RGBA", (cell * 4, cell * 4), (0, 0, 0, 0))

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

    shapes = [(soft, 3.5), star, heart, spark, ring, flame, leaf, note, pixel, (puff, 1.2), snow, coin, bolt, petal, drop, confetti]
    for i, shape in enumerate(shapes):
        fn, blur = shape if isinstance(shape, tuple) else (shape, 0.0)
        mask = cell_img(fn, blur)
        x, y = (i % 4) * cell, (i // 4) * cell
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
    make_logo(brand / "logo.png")
    make_icons()
    print("art done")


if __name__ == "__main__":
    main()
