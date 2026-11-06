"""The game's logo: a little planet with a flag planted on it, behind the name in fat cartoon letters. BASE is split down the
middle by a white bolt, half in each team's colour, because that line is what the game is about.

    python tools/gen_logo.py [out.png] [font.ttf]
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = str(ROOT / "tools/fonts/LuckiestGuy-Regular.ttf")
INK = (10, 20, 38)
WHITE = (255, 255, 255)


def grad(size, top, low, power=1.0):
    w, h = size
    column = Image.new("RGB", (1, h))
    for y in range(h):
        t = (y / max(h - 1, 1)) ** power
        column.putpixel((0, y), tuple(int(top[i] + (low[i] - top[i]) * t) for i in range(3)))
    return column.resize((w, h))


def grow(mask, amount):
    """Fattens a mask evenly, without the slowness of a big max filter."""
    if amount <= 0:
        return mask
    blurred = mask.filter(ImageFilter.GaussianBlur(amount * 0.62))
    return blurred.point(lambda v: 255 if v > 26 else int(v * 255 / 26))


def shrink(mask, amount):
    blurred = mask.filter(ImageFilter.GaussianBlur(amount * 0.62))
    return blurred.point(lambda v: 0 if v < 228 else int((v - 228) * 255 / 27))


def letter(ch, font, face_top, face_low, side, depth, ink_w):
    """One fat letter: a dark outline, a thick side going down, a white rim, a glossy face and a bright top edge."""
    box = font.getbbox(ch)
    w, h = box[2] - box[0], box[3] - box[1]
    pad = ink_w * 3 + depth + 10
    size = (w + pad * 2, h + pad * 2)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).text((pad - box[0], pad - box[1]), ch, font=font, fill=255)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    fat = grow(mask, int(ink_w * 0.5))
    # The ink, round the face and its side together.
    outer = grow(fat, ink_w)
    for dy in range(0, depth + 1, 2):
        img.paste(Image.new("RGBA", size, INK + (255,)), (0, dy), outer)
    # The side of the letter, darkening as it goes down.
    for dy in range(depth, 0, -1):
        f = dy / max(depth, 1)
        c = tuple(int(side[i] * (1.0 - f * 0.34)) for i in range(3))
        img.paste(Image.new("RGBA", size, c + (255,)), (0, dy), fat)
    # A white rim, then the face.
    img.paste(Image.new("RGBA", size, WHITE + (255,)), (0, 0), fat)
    face_mask = shrink(fat, int(ink_w * 0.44))
    face = grad(size, face_top, face_low, 0.85).convert("RGBA")
    img.paste(face, (0, 0), face_mask)
    # A curved band of light over the top half of the face.
    gloss = Image.new("L", size, 0)
    gd = ImageDraw.Draw(gloss)
    gd.ellipse((-w * 0.3 + pad, pad - h * 0.72, w * 1.3 + pad, pad + h * 0.44), fill=78)
    gloss = gloss.filter(ImageFilter.GaussianBlur(2))
    gloss_mask = Image.composite(gloss, Image.new("L", size, 0), face_mask)
    img.paste(Image.new("RGBA", size, WHITE + (255,)), (0, 0), gloss_mask)
    return img


def place(canvas, img, cx, cy, tilt):
    turned = img.rotate(tilt, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(turned, (int(cx - turned.width / 2), int(cy - turned.height / 2)))


def star(cx, cy, big, small=None, n=5, rot=-math.pi / 2):
    small = small or big * 0.46
    pts = []
    for i in range(n * 2):
        r = big if i % 2 == 0 else small
        a = rot + math.pi * i / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


# Rough shapes of the continents, as (longitude, latitude), for the planet here and for the one on the title screen.
CONTINENTS = [
    [(-168, 66), (-156, 71), (-128, 70), (-95, 74), (-80, 72), (-62, 60), (-56, 52), (-68, 45), (-76, 36), (-81, 27), (-90, 29), (-97, 22), (-90, 15), (-83, 9), (-78, 8), (-88, 13), (-105, 20), (-114, 30), (-124, 40), (-125, 50), (-140, 60), (-158, 57)],
    [(-78, 9), (-62, 10), (-50, 2), (-35, -6), (-39, -18), (-48, -26), (-57, -36), (-65, -46), (-70, -54), (-74, -46), (-71, -30), (-70, -18), (-80, -6), (-79, 2)],
    [(-17, 15), (-16, 26), (-6, 35), (10, 37), (22, 32), (33, 30), (37, 20), (43, 12), (51, 11), (42, -2), (39, -14), (34, -24), (26, -34), (18, -34), (13, -18), (9, -2), (6, 4), (-8, 5)],
    [(-10, 37), (-9, 43), (-2, 44), (-4, 49), (3, 51), (8, 55), (6, 60), (14, 66), (24, 70), (30, 66), (28, 60), (40, 55), (50, 46), (38, 45), (28, 41), (24, 36), (18, 40), (14, 44), (8, 44), (0, 39)],
    [(28, 41), (36, 37), (35, 30), (43, 15), (53, 17), (59, 24), (66, 25), (72, 20), (78, 8), (82, 16), (90, 22), (98, 16), (103, 2), (108, 12), (108, 21), (120, 30), (122, 38), (130, 42), (140, 52), (160, 60), (178, 66), (170, 72), (130, 74), (100, 77), (70, 73), (45, 68), (30, 66), (28, 60), (40, 55), (50, 46)],
    [(113, -22), (122, -18), (130, -12), (137, -15), (142, -11), (146, -19), (153, -27), (150, -37), (140, -38), (130, -32), (116, -34), (114, -28)],
    [(-55, 60), (-44, 60), (-22, 70), (-20, 80), (-50, 83), (-70, 78), (-58, 70)],
    [(-180, -72), (-120, -74), (-60, -66), (0, -70), (60, -68), (120, -67), (180, -72), (180, -90), (-180, -90)],
    [(44, -16), (50, -14), (47, -25), (44, -24)],
    [(130, 32), (136, 36), (141, 41), (143, 44), (141, 37), (136, 33)],
    [(-5, 50), (1, 51), (-2, 57), (-6, 58), (-5, 54)],
    [(95, 5), (106, -6), (115, -8), (120, -9), (116, -3), (118, 3), (110, 2), (100, 2)],
    [(172, -41), (178, -38), (175, -46), (168, -46)],
    [(120, 18), (124, 13), (126, 7), (122, 7), (120, 13)],
]


def world_map(width=1024):
    """The planet's skin, laid out flat: sea, sand, grass, and snow at the top and bottom."""
    h = width // 2
    big = 2
    mask = Image.new("L", (width * big, h * big), 0)
    d = ImageDraw.Draw(mask)

    def at(lon, lat):
        return ((lon + 180) / 360 * width * big, (90 - lat) / 180 * h * big)

    for shape in CONTINENTS:
        d.polygon([at(*p) for p in shape], fill=255)
    soft = mask.filter(ImageFilter.GaussianBlur(9 * big)).resize((width, h), Image.LANCZOS)
    img = grad((width, h), (58, 168, 255), (36, 132, 240)).convert("RGB")
    shallow = soft.point(lambda v: 255 if v > 40 else int(v * 255 / 40))
    img.paste(Image.new("RGB", (width, h), (118, 214, 255)), (0, 0), shallow)
    sand = soft.point(lambda v: 255 if v > 104 else (0 if v < 92 else int((v - 92) * 255 / 12)))
    img.paste(Image.new("RGB", (width, h), (255, 232, 160)), (0, 0), sand)
    land_mask = soft.point(lambda v: 255 if v > 122 else (0 if v < 110 else int((v - 110) * 255 / 12)))
    land = grad((width, h), (150, 226, 110), (92, 200, 92)).convert("RGB")
    img.paste(land, (0, 0), land_mask)
    # Deserts and forests, for something to look at.
    patches = Image.new("L", (width, h), 0)
    pd = ImageDraw.Draw(patches)
    for lon, lat, rx, ry in [(10, 22, 28, 9), (45, 24, 13, 7), (130, -26, 11, 6), (-110, 34, 8, 6), (95, 40, 18, 6)]:
        x, y = at(lon, lat)
        pd.ellipse((x / big - rx * width / 360, y / big - ry * h / 180, x / big + rx * width / 360, y / big + ry * h / 180), fill=255)
    patches = patches.filter(ImageFilter.GaussianBlur(5))
    img.paste(Image.new("RGB", (width, h), (240, 208, 130)), (0, 0), Image.composite(patches, Image.new("L", (width, h), 0), land_mask))
    forest = Image.new("L", (width, h), 0)
    fd = ImageDraw.Draw(forest)
    for lon, lat, rx, ry in [(-62, -6, 15, 9), (22, -2, 11, 7), (105, 58, 40, 7), (-100, 56, 24, 7), (110, 8, 10, 6)]:
        x, y = at(lon, lat)
        fd.ellipse((x / big - rx * width / 360, y / big - ry * h / 180, x / big + rx * width / 360, y / big + ry * h / 180), fill=255)
    forest = forest.filter(ImageFilter.GaussianBlur(5))
    img.paste(Image.new("RGB", (width, h), (46, 168, 84)), (0, 0), Image.composite(forest, Image.new("L", (width, h), 0), land_mask))
    snow = Image.new("L", (width, h), 0)
    sd = ImageDraw.Draw(snow)
    sd.rectangle((0, 0, width, h * 0.09), fill=255)
    sd.rectangle((0, h * 0.93, width, h), fill=255)
    img.paste(Image.new("RGB", (width, h), (248, 252, 255)), (0, 0), snow.filter(ImageFilter.GaussianBlur(5)))
    return img


def globe(canvas, cx, cy, r):
    """A ball with the map wrapped round it, looking at Africa and Europe, with a dark edge, a shine and a soft shade."""
    flat = world_map(1024).convert("RGB")
    size = int(r * 2)
    ball = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = ball.load()
    src = flat.load()
    mw, mh = flat.size
    tilt = math.radians(14)
    turn = math.radians(18)
    for y in range(size):
        ny = (y + 0.5 - r) / r
        for x in range(size):
            nx = (x + 0.5 - r) / r
            d2 = nx * nx + ny * ny
            if d2 > 1.0:
                continue
            nz = math.sqrt(1.0 - d2)
            # Tip the ball forward, then read off the map.
            yy = -ny * math.cos(tilt) + nz * math.sin(tilt)
            zz = ny * math.sin(tilt) + nz * math.cos(tilt)
            lat = math.asin(max(-1.0, min(1.0, yy)))
            lon = math.atan2(nx, zz) + turn
            u = int(((lon / math.tau + 0.5) % 1.0) * (mw - 1))
            v = int((0.5 - lat / math.pi) * (mh - 1))
            c = src[u, v]
            light = 0.72 + 0.34 * max(0.0, (-nx * 0.45 - ny * 0.62 + nz * 0.62))
            px[x, y] = (min(int(c[0] * light), 255), min(int(c[1] * light), 255), min(int(c[2] * light), 255), 255)
    mask = Image.new("L", (size * 2, size * 2), 0)
    ImageDraw.Draw(mask).ellipse((2, 2, size * 2 - 2, size * 2 - 2), fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    ball.putalpha(mask)
    d = ImageDraw.Draw(canvas)
    edge = int(r * 0.075)
    d.ellipse((cx - r - edge - 14, cy - r - edge - 14, cx + r + edge + 14, cy + r + edge + 14), fill=INK + (255,))
    d.ellipse((cx - r - edge, cy - r - edge, cx + r + edge, cy + r + edge), fill=WHITE + (255,))
    canvas.alpha_composite(ball, (int(cx - r), int(cy - r)))
    shine = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(shine).ellipse((cx - r * 0.72, cy - r * 0.86, cx - r * 0.02, cy - r * 0.42), fill=110)
    canvas.paste(Image.new("RGBA", canvas.size, WHITE + (255,)), (0, 0), shine.filter(ImageFilter.GaussianBlur(r * 0.04)))


def team_flag(canvas, x, base_y, height, width):
    """A flag on a pole, half in each team's colour, with a star where they meet."""
    d = ImageDraw.Draw(canvas)
    top = base_y - height
    pole = max(int(width * 0.05), 8)
    d.rounded_rectangle((x - pole - 10, top - 12, x + pole + 10, base_y + 10), radius=pole, fill=INK + (255,))
    d.rounded_rectangle((x - pole, top, x + pole, base_y), radius=pole, fill=(255, 246, 224, 255))
    upper, lower = [], []
    drop = height * 0.5
    for i in range(41):
        f = i / 40
        y = top + height * 0.05 + math.sin(f * 6.4 + 0.5) * height * 0.04 * (0.3 + f)
        upper.append((x + pole + f * width, y + f * drop * 0.16))
        lower.append((x + pole + f * width, y + drop - f * drop * 0.2))
    shape = upper + lower[::-1]
    d.line(shape + [shape[0]], fill=INK + (255,), width=26, joint="curve")
    d.polygon(shape, fill=(255, 178, 31, 255))
    half = upper[:21] + lower[:21][::-1]
    far = upper[20:] + lower[20:][::-1]
    d.polygon(half, fill=(255, 178, 31, 255))
    d.polygon(far, fill=(35, 167, 255, 255))
    mid_x, mid_y = upper[20][0], (upper[20][1] + lower[20][1]) / 2
    d.polygon(star(mid_x, mid_y, drop * 0.34), fill=INK + (255,))
    d.polygon(star(mid_x, mid_y, drop * 0.25), fill=WHITE + (255,))
    d.ellipse((x - pole * 2.6, top - pole * 3.2, x + pole * 2.6, top + pole * 1.6), fill=INK + (255,))
    d.ellipse((x - pole * 1.9, top - pole * 2.5, x + pole * 1.9, top + pole * 0.9), fill=(255, 226, 92, 255))


def sparkle(canvas, cx, cy, s, colour=WHITE):
    d = ImageDraw.Draw(canvas)
    d.polygon(star(cx, cy, s * 1.25, s * 0.34, 4), fill=INK + (255,))
    d.polygon(star(cx, cy, s, s * 0.2, 4), fill=colour + (255,))


def crystal(canvas, cx, cy, s):
    d = ImageDraw.Draw(canvas)
    outline = [(cx - s * 0.56, cy - s * 0.62), (cx + s * 0.56, cy - s * 0.62), (cx + s, cy - s * 0.14), (cx, cy + s), (cx - s, cy - s * 0.14)]
    d.polygon([(cx + (px - cx) * 1.2, cy + (py - cy) * 1.2) for px, py in outline], fill=INK + (255,))
    d.polygon(outline, fill=(255, 111, 181, 255))
    d.polygon([(cx - s * 0.56, cy - s * 0.62), (cx - s * 0.18, cy - s * 0.62), (cx - s * 0.34, cy - s * 0.14), (cx - s, cy - s * 0.14)], fill=(255, 90, 78, 255))
    d.polygon([(cx - s * 0.18, cy - s * 0.62), (cx + s * 0.18, cy - s * 0.62), (cx + s * 0.34, cy - s * 0.14), (cx - s * 0.34, cy - s * 0.14)], fill=(255, 210, 63, 255))
    d.polygon([(cx + s * 0.18, cy - s * 0.62), (cx + s * 0.56, cy - s * 0.62), (cx + s, cy - s * 0.14), (cx + s * 0.34, cy - s * 0.14)], fill=(53, 208, 127, 255))
    d.polygon([(cx - s, cy - s * 0.14), (cx - s * 0.34, cy - s * 0.14), (cx, cy + s)], fill=(183, 104, 255, 255))
    d.polygon([(cx - s * 0.34, cy - s * 0.14), (cx + s * 0.34, cy - s * 0.14), (cx, cy + s)], fill=(58, 166, 255, 255))
    d.polygon([(cx + s * 0.34, cy - s * 0.14), (cx + s, cy - s * 0.14), (cx, cy + s)], fill=(126, 232, 255, 255))


def wide(img, by):
    """Fatter still: the letters read better a little stretched."""
    return img.resize((int(img.width * by), img.height), Image.LANCZOS)


def make_logo(path, width=1800, font_path=None):
    font_path = font_path or FONT
    # Everything's drawn twice the size, for smooth edges.
    W = width * 2
    H = int(W * 0.74)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mid = W // 2
    # The planet, with its flag, behind the words.
    r = int(W * 0.135)
    globe_y = int(H * 0.335)
    globe(canvas, mid, globe_y, r)
    team_flag(canvas, mid + int(r * 0.12), globe_y - int(r * 0.92), int(r * 0.74), int(r * 0.92))
    # CAPTURE across the planet's middle, on a shallow arch.
    stretch_top = 1.2
    size_top = int(W * 0.122)
    font_top = ImageFont.truetype(font_path, size_top)
    word = "CAPTURE"
    advance = [font_top.getlength(c) * 1.03 * stretch_top for c in word]
    total = sum(advance)
    x = mid - total / 2
    arch_y = H * 0.375
    for i, ch in enumerate(word):
        cx = x + advance[i] / 2
        off = (cx - mid) / (total / 2)
        y = arch_y + off * off * H * 0.05
        tilt = -off * 6.0
        img = wide(letter(ch, font_top, (255, 255, 255), (178, 232, 255), (24, 92, 200), int(size_top * 0.1), int(size_top * 0.05)), stretch_top)
        place(canvas, img, cx, y, tilt)
        x += advance[i]
    # BASE below it: huge, and split down the middle.
    stretch_big = 1.22
    size_big = int(W * 0.215)
    font_big = ImageFont.truetype(font_path, size_big)
    word = "BASE"
    advance = [font_big.getlength(c) * stretch_big for c in word]
    gap = size_big * 0.3  # Room for the bolt.
    total = sum(advance) + gap
    x = mid - total / 2
    base_y = H * 0.645
    sun = ((255, 226, 92), (255, 150, 30), (196, 88, 12))
    wave = ((130, 226, 255), (28, 136, 244), (12, 76, 170))
    for i, ch in enumerate(word):
        if i == 2:
            x += gap
        cx = x + advance[i] / 2
        team = sun if i < 2 else wave
        img = wide(letter(ch, font_big, team[0], team[1], team[2], int(size_big * 0.085), int(size_big * 0.035)), stretch_big)
        place(canvas, img, cx, base_y + [8, -6, -6, 8][i] * 2, [3.0, 1.2, -1.2, -3.0][i])
        x += advance[i]
    # The line between them: a white bolt, top to bottom.
    d = ImageDraw.Draw(canvas)
    u = size_big * 0.1
    top = base_y - size_big * 0.62
    bolt = [(mid + u * 0.9, top), (mid - u * 1.0, base_y + u * 0.5), (mid + u * 0.05, base_y + u * 0.5), (mid - u * 0.9, top + size_big * 1.26), (mid + u * 1.0, base_y - u * 0.7), (mid - u * 0.05, base_y - u * 0.7)]
    d.line(bolt + bolt[:2], fill=INK + (255,), width=int(u * 0.62), joint="curve")
    d.polygon(bolt, fill=WHITE + (255,))
    # THE, in a little round tag tucked between the words.
    font_the = ImageFont.truetype(font_path, int(W * 0.036))
    tag = (mid - total * 0.5 + W * 0.02, H * 0.465)
    tr = W * 0.044
    d.ellipse((tag[0] - tr - 12, tag[1] - tr - 12, tag[0] + tr + 12, tag[1] + tr + 12), fill=INK + (255,))
    d.ellipse((tag[0] - tr, tag[1] - tr, tag[0] + tr, tag[1] + tr), fill=(255, 90, 78, 255))
    d.ellipse((tag[0] - tr * 0.86, tag[1] - tr * 0.86, tag[0] + tr * 0.86, tag[1] + tr * 0.1), fill=(255, 128, 112, 255))
    bb = d.textbbox((0, 0), "THE", font=font_the)
    d.text((tag[0] - (bb[2] - bb[0]) / 2 - bb[0], tag[1] - (bb[3] - bb[1]) / 2 - bb[1]), "THE", font=font_the, fill=WHITE + (255,))
    # A crystal and some sparkle.
    crystal(canvas, mid + total * 0.5 - W * 0.012, H * 0.455, W * 0.034)
    sparkle(canvas, mid - r * 1.5, globe_y - r * 0.6, W * 0.024)
    sparkle(canvas, mid + r * 1.9, globe_y - r * 0.2, W * 0.018, (255, 226, 92))
    sparkle(canvas, mid - total * 0.53, H * 0.82, W * 0.016, (255, 226, 92))
    # A soft shadow under the lot, then down to size.
    alpha = canvas.getchannel("A")
    shadow = Image.new("RGBA", canvas.size, (4, 9, 18, 0))
    shadow.putalpha(alpha.point(lambda v: int(v * 0.42)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(W * 0.004))
    out = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (0, int(W * 0.007)))
    out.alpha_composite(canvas)
    out = out.crop(out.getbbox())
    out = out.resize((out.width // 2, out.height // 2), Image.LANCZOS)
    out.save(path, optimize=True)
    return out


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "assets/brand/logo.png")
    make_logo(target, font_path=sys.argv[2] if len(sys.argv) > 2 else None)
    print("logo done:", target)
