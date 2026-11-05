"""Draws the game's logo, app icons and particle atlas (original art, made here with Pillow).

The logo spells the name out in toy building blocks.

    python tools/gen_art.py
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
TITLE_FONT = str(ROOT / "assets/fonts/RammettoOne-Regular.ttf")

INK = (18, 58, 107)
INK_DARK = (10, 38, 74)
WHITE = (255, 255, 255)
CORAL = (255, 82, 71)
MINT = (53, 208, 127)
SKY_TOP = (69, 178, 255)
SKY_LOW = (194, 240, 255)
GRASS = (88, 200, 92)
GRASS_DARK = (62, 170, 70)
# Block colours: face top, face bottom, side.
BLOCKS = {
    "red": ((255, 110, 92), (240, 62, 54), (176, 34, 38)),
    "yellow": ((255, 226, 92), (255, 182, 28), (214, 124, 10)),
    "blue": ((104, 198, 255), (38, 138, 244), (20, 88, 182)),
    "green": ((112, 234, 120), (46, 196, 88), (22, 134, 62)),
    "orange": ((255, 184, 92), (255, 136, 36), (206, 88, 14)),
    "pink": ((255, 150, 200), (255, 84, 160), (192, 40, 116)),
    "teal": ((104, 232, 224), (30, 190, 196), (14, 130, 142)),
}


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


def toy_block(size, colours, letter=None, font=None):
    """A rounded plastic cube, seen a little from above, with a letter on its face. Returns an RGBA picture."""
    top, low, side = colours
    depth = int(size * 0.17)
    pad = int(size * 0.06)
    w = size + pad * 2
    h = size + depth + pad * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    radius = int(size * 0.2)
    box = (pad, pad, pad + size, pad + size)
    # The side of the block below its face, then a soft shadow line under the whole thing.
    d.rounded_rectangle((pad, pad + depth, pad + size, pad + size + depth), radius=radius, fill=INK_DARK + (255,))
    d.rounded_rectangle((pad, pad + depth - int(size * 0.02), pad + size, pad + size + depth - int(size * 0.03)), radius=radius, fill=side + (255,))
    # The face, shading from top to bottom.
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle(box, radius=radius, fill=255)
    face = vgrad((w, h), top, low, 0.9).convert("RGBA")
    img.paste(face, (0, 0), mask)
    # A soft rim of light round the face, and a highlight on the top edge, so it reads as glossy plastic.
    rim = Image.new("L", (w, h), 0)
    border = max(int(size * 0.035), 2)
    ImageDraw.Draw(rim).rounded_rectangle(box, radius=radius, outline=120, width=border)
    img.paste(Image.new("RGBA", (w, h), WHITE + (255,)), (0, 0), rim)
    gloss = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(gloss)
    gd.rounded_rectangle((pad + size * 0.1, pad + size * 0.075, pad + size * 0.9, pad + size * 0.28), radius=int(size * 0.1), fill=120)
    gloss = gloss.filter(ImageFilter.GaussianBlur(size * 0.012))
    img.paste(Image.new("RGBA", (w, h), WHITE + (255,)), (0, 0), gloss)
    if letter:
        # The letter sits on the face, with a little dark drop below it.
        layer = Image.new("L", (w, h), 0)
        ld = ImageDraw.Draw(layer)
        bb = ld.textbbox((0, 0), letter, font=font)
        x = pad + (size - (bb[2] - bb[0])) / 2 - bb[0]
        y = pad + (size - (bb[3] - bb[1])) / 2 - bb[1] + size * 0.015
        ld.text((x, y), letter, font=font, fill=255)
        drop = ImageChops.offset(layer, 0, int(size * 0.035))
        img.paste(Image.new("RGBA", (w, h), side + (255,)), (0, 0), drop)
        img.paste(Image.new("RGBA", (w, h), WHITE + (255,)), (0, 0), layer)
    return img


def place(canvas, block, cx, cy, tilt):
    turned = block.rotate(tilt, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(turned, (int(cx - turned.width / 2), int(cy - turned.height / 2)))


def drop_shadow(canvas, offset, blur, opacity):
    alpha = canvas.getchannel("A")
    shadow = Image.new("RGBA", canvas.size, INK_DARK + (0,))
    shadow.putalpha(alpha.point(lambda v: int(v * opacity)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (offset[0], offset[1]))
    out.alpha_composite(canvas)
    return out


def flag(canvas, x, base_y, height, width, colour):
    d = ImageDraw.Draw(canvas)
    top = base_y - height
    pole = max(int(width * 0.07), 5)
    d.rounded_rectangle((x - pole - 3, top - 3, x + pole + 3, base_y + 3), radius=pole, fill=INK_DARK + (255,))
    d.rounded_rectangle((x - pole, top, x + pole, base_y), radius=pole, fill=(255, 246, 224, 255))
    wave = []
    bottom = []
    drop = height * 0.5
    for i in range(21):
        f = i / 20
        y = top + height * 0.05 + math.sin(f * 5.2) * height * 0.035
        wave.append((x + pole + f * width, y + f * drop * 0.2))
        bottom.append((x + pole + f * width, y + drop - f * drop * 0.34))
    outline = wave + list(reversed(bottom))
    d.polygon([(a + 5, b + 6) for a, b in outline], fill=INK_DARK + (255,))
    d.polygon(outline, fill=colour + (255,))
    cx = x + pole + width * 0.45
    cy = top + height * 0.05 + drop * 0.46
    d.polygon(star_points(cx, cy, drop * 0.34, drop * 0.15), fill=(255, 226, 92, 255))
    d.ellipse((x - pole * 2.2, top - pole * 2.6, x + pole * 2.2, top + pole * 1.8), fill=INK_DARK + (255,))
    d.ellipse((x - pole * 1.7, top - pole * 2.1, x + pole * 1.7, top + pole * 1.3), fill=(255, 226, 92, 255))


def make_logo(path, width=1600):
    h = int(width * 0.7)
    canvas = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    small = int(width * 0.128)
    big = int(width * 0.2)
    font_small = ImageFont.truetype(TITLE_FONT, int(small * 0.66))
    font_big = ImageFont.truetype(TITLE_FONT, int(big * 0.66))
    random.seed(4)
    # BASE first, bigger and at the front; the flag stands on it.
    colours = ["blue", "red", "yellow", "green"]
    gap = big * 1.06
    start = width * 0.5 - gap * 1.5
    y_base = h * 0.66
    flag(canvas, int(start + gap * 3 + big * 0.1), int(y_base - big * 0.44), int(big * 1.02), int(big * 0.72), (255, 82, 71))
    for i, letter in enumerate("BASE"):
        place(canvas, toy_block(big, BLOCKS[colours[i]], letter, font_big), start + i * gap, y_base + [6, -8, 8, -4][i], [-4, 3, -2, 4][i])
    # CAPTURE on top, in smaller blocks, overlapping the row below like a stack.
    colours = ["red", "yellow", "green", "blue", "orange", "pink", "teal"]
    gap = small * 1.03
    start = width * 0.5 - gap * 3 - width * 0.03
    y_top = h * 0.24
    for i, letter in enumerate("CAPTURE"):
        place(canvas, toy_block(small, BLOCKS[colours[i]], letter, font_small), start + i * gap, y_top + [6, -6, 7, -5, 6, -7, 5][i], [3, -3, 2, -2, 3, -3, 2][i])
    # "the": a little round wooden peg between the rows.
    d = ImageDraw.Draw(canvas)
    cx, cy, r = width * 0.095, h * 0.5, width * 0.062
    d.ellipse((cx - r, cy - r + r * 0.2, cx + r, cy + r + r * 0.2), fill=INK_DARK + (255,))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 226, 92, 255))
    d.ellipse((cx - r * 0.84, cy - r * 0.84, cx + r * 0.84, cy + r * 0.84), fill=(255, 240, 160, 255))
    font_the = ImageFont.truetype(TITLE_FONT, int(r * 0.74))
    bb = d.textbbox((0, 0), "THE", font=font_the)
    d.text((cx - (bb[2] - bb[0]) / 2 - bb[0], cy - (bb[3] - bb[1]) / 2 - bb[1]), "THE", font=font_the, fill=INK + (255,))
    canvas = drop_shadow(canvas, (0, int(width * 0.008)), width * 0.005, 0.45)
    canvas = canvas.crop(canvas.getbbox())
    canvas.save(path, optimize=True)


def emblem_layer(size):
    """The mark: one big toy block with a star on it, and a flag planted on top."""
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    block_size = int(s * 0.56)
    block = toy_block(block_size, BLOCKS["blue"])
    d = ImageDraw.Draw(block)
    mid = block.width / 2
    d.polygon(star_points(mid, mid + block_size * 0.01, block_size * 0.36, block_size * 0.16), fill=(214, 124, 10, 255))
    d.polygon(star_points(mid, mid - block_size * 0.015, block_size * 0.34, block_size * 0.15), fill=(255, 226, 92, 255))
    flag(img, int(s * 0.5), int(s * 0.46), int(s * 0.36), int(s * 0.28), (255, 82, 71))
    place(img, block, s * 0.5, s * 0.62, -5)
    return img


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
