"""Draws the game's icons and power cards. All of it is original art made of simple shapes, in one style: round,
chunky stickers with a single dark outline round the whole shape and no lines inside, to match the avatars.

    python tools/gen_icons.py

Writes assets/icons/ui/*.svg (buttons and menus) and assets/icons/power/*.svg (a card for every power, plus the
card back). The card's name is added by the game (ui/PowerCard.gd), in the game's font.
"""
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

INK = "#0a1426"
OUTLINE = 34
W = "#ffffff"
CREAM = "#fff6dd"
RED = "#ff5a4e"
DRED = "#c9302a"
ORANGE = "#ff9d2e"
YELLOW = "#ffd23f"
GOLD = "#ffb21f"
GREEN = "#35d07f"
DGREEN = "#1a9c58"
LEAF = "#7ed957"
BLUE = "#3aa6ff"
DBLUE = "#1a6fd0"
CYAN = "#7ee8ff"
PURPLE = "#b768ff"
DPURPLE = "#7f38d6"
PINK = "#ff6fb5"
GRAY = "#1c2740"
DGRAY = "#0a1426"
BROWN = "#b5763c"
DBROWN = "#7a4a26"
BLACK = "#2b2448"
SKIN = "#f0c090"


def shape(tag, geo, fill, ol, soft, op, line=0):
    extra = f' opacity="{op}"' if op is not None else ""
    round_ends = 'stroke-linejoin="round" stroke-linecap="round"'
    if line:
        out = f'<{tag} {geo} fill="none" stroke="{INK}" stroke-width="{line + OUTLINE}" {round_ends}/>'
        top = f'<{tag} {geo} fill="none" stroke="{fill}" stroke-width="{line}" {round_ends}{extra}/>'
    else:
        out = f'<{tag} {geo} fill="{INK}" stroke="{INK}" stroke-width="{OUTLINE + soft}" {round_ends}/>'
        top = f'<{tag} {geo} fill="{fill}" stroke="{fill}" stroke-width="{soft}" {round_ends}{extra}/>' if soft else f'<{tag} {geo} fill="{fill}"{extra}/>'
    return {"o": out if ol else "", "f": top}


def C(x, y, r, f, ol=True, op=None):
    return shape("circle", f'cx="{x}" cy="{y}" r="{r}"', f, ol, 0, op)


def E(x, y, rx, ry, f, rot=0, ol=True, op=None):
    turn = f' transform="rotate({rot} {x} {y})"' if rot else ""
    return shape("ellipse", f'cx="{x}" cy="{y}" rx="{rx}" ry="{ry}"{turn}', f, ol, 0, op)


def R(x, y, w, h, r, f, rot=0, ol=True, op=None):
    turn = f' transform="rotate({rot} {x + w / 2} {y + h / 2})"' if rot else ""
    return shape("rect", f'x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"{turn}', f, ol, 0, op)


def P(points, f, ol=True, soft=14, op=None):
    return shape("polygon", f'points="{points}"', f, ol, soft, op)


def D(d, f, ol=True, soft=8, op=None):
    return shape("path", f'd="{d}"', f, ol, soft, op)


def L(points, width, f, ol=True, op=None):
    return shape("polyline", f'points="{points}"', f, ol, 0, op, width)


def K(d, width, f, ol=True, op=None):
    return shape("path", f'd="{d}"', f, ol, 0, op, width)


def G(transform, *items):
    return [{"o": f'<g transform="{transform}">{s["o"]}</g>' if s["o"] else "", "f": f'<g transform="{transform}">{s["f"]}</g>'} for s in flat(items)]


def flat(items):
    out = []
    for item in items:
        if isinstance(item, (list, tuple)):
            out.extend(flat(item))
        else:
            out.append(item)
    return out


def body(*items):
    shapes = flat(items)
    return "".join(s["o"] for s in shapes) + "".join(s["f"] for s in shapes)


# --- Little parts that many icons share -----------------------------------------------------------------

def shine(x, y, rx, ry, rot=-30):
    return E(x, y, rx, ry, W, rot, False, 0.55)


def star(x, y, big, f=YELLOW, ol=True, rot=-90, points=5, ratio=0.5):
    pts = []
    for i in range(points * 2):
        a = math.radians(rot) + math.pi * i / points
        r = big if i % 2 == 0 else big * ratio
        pts.append(f"{x + math.cos(a) * r:.1f},{y + math.sin(a) * r:.1f}")
    return P(" ".join(pts), f, ol, max(6, big // 5))


def spark(x, y, big, f=W, ol=False):
    pts = []
    for i in range(8):
        a = math.pi * i / 4 - math.pi / 2
        r = big if i % 2 == 0 else big * 0.26
        pts.append(f"{x + math.cos(a) * r:.1f},{y + math.sin(a) * r:.1f}")
    return P(" ".join(pts), f, ol, 4)


def bolt(x, y, s, f=YELLOW, ol=True):
    pts = [(10, -100), (-52, 16), (-6, 16), (-22, 100), (54, -24), (8, -24), (34, -100)]
    return P(" ".join(f"{x + a * s:.1f},{y + b * s:.1f}" for a, b in pts), f, ol, 10)


def heart(x, y, s, f=PINK, ol=True):
    return G(f"translate({x} {y}) scale({s})", D("M0 90 C-110 10 -110 -80 -48 -80 C-20 -80 0 -55 0 -40 C0 -55 20 -80 48 -80 C110 -80 110 10 0 90 Z", f, ol))


def cloud(x, y, s, f=W, ol=True):
    return G(f"translate({x} {y}) scale({s})", C(-80, 10, 58, f, ol), C(0, -26, 76, f, ol), C(84, 8, 60, f, ol), R(-130, 0, 268, 66, 33, f, 0, ol))


def flame(x, y, s, f=ORANGE, inner=YELLOW, ol=True):
    return G(f"translate({x} {y}) scale({s})",
             D("M0 -110 C30 -60 88 -30 88 34 C88 86 46 110 0 110 C-46 110 -88 86 -88 34 C-88 -6 -58 -24 -44 -60 C-30 -34 -18 -40 0 -110 Z", f, ol),
             D("M0 -14 C14 14 44 28 44 58 C44 86 22 98 0 98 C-22 98 -44 86 -44 58 C-44 28 -14 14 0 -14 Z", inner, False))


def person(x, y, s, shirt=RED, tone=SKIN, hair=BLACK, ol=True):
    return G(f"translate({x} {y}) scale({s})",
             R(-58, 34, 116, 96, 46, shirt, 0, ol),
             C(0, -38, 72, tone, ol),
             D("M-70 -46 C-70 -120 70 -120 70 -46 C40 -68 -40 -68 -70 -46 Z", hair, False),
             E(-24, -30, 9, 13, BLACK, 0, False), E(24, -30, 9, 13, BLACK, 0, False))


def ghost(x, y, s, f="#eef1ff", face=True, ol=True):
    parts = [D("M-100 110 L-100 -10 C-100 -140 100 -140 100 -10 L100 110 L60 82 L20 110 L-20 82 L-60 110 Z", f, ol)]
    if face:
        parts += [E(-36, -12, 15, 22, BLACK, 0, False), E(36, -12, 15, 22, BLACK, 0, False), E(0, 28, 12, 16, BLACK, 0, False),
                  E(-62, 18, 15, 9, PINK, 0, False, 0.6), E(62, 18, 15, 9, PINK, 0, False, 0.6)]
    return G(f"translate({x} {y}) scale({s})", parts)


def question(x, y, s, f=W, ol=True):
    return G(f"translate({x} {y}) scale({s})",
             K("M-46 -40 C-46 -104 56 -104 56 -40 C56 -6 4 -4 4 34", 36, f, ol), C(4, 92, 25, f, ol))


def crystal(x=256, y=256, s=1.0, colours=None, ol=True):
    """A cut gem. The colours go from the left of its top round to the bottom."""
    c = colours or [RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, PINK]
    t = [(-100, -128), (100, -128), (196, -36), (0, 180), (-196, -36)]
    outline = P(" ".join(f"{a},{b}" for a, b in t), c[0], ol, 22)
    facets = [
        P("-100,-128 -40,-128 -66,-36 -196,-36", c[0], False, 2),
        P("-40,-128 40,-128 66,-36 -66,-36", c[1], False, 2),
        P("40,-128 100,-128 196,-36 66,-36", c[2], False, 2),
        P("-196,-36 -66,-36 0,180", c[6], False, 2),
        P("-66,-36 66,-36 0,180", c[4], False, 2),
        P("66,-36 196,-36 0,180", c[3], False, 2),
    ]
    return G(f"translate({x} {y}) scale({s})", outline, facets, E(-84, -84, 32, 13, W, -20, False, 0.6))


RAINBOW = None
BLUES = ["#5fd4ff", "#a8f0ff", "#7ee8ff", "#3aa6ff", "#1a8ae0", "#1a6fd0", "#3aa6ff"]


def arrow(d, tip, width, f, ol=True):
    """A curved line with a rounded arrowhead: `tip` is the head's points."""
    return [K(d, width, f, ol), P(tip, f, ol, 12)]


def shoe(x, y, s, f=RED, sole=W):
    return G(f"translate({x} {y}) scale({s})",
             D("M-150 62 C-170 0 -150 -110 -80 -122 C-40 -128 -30 -72 10 -50 C54 -26 150 -24 150 40 C150 64 130 78 104 78 L-120 78 C-138 78 -146 72 -150 62 Z", f),
             R(-162, 52, 322, 54, 27, sole),
             L("-34,-66 6,-28", 18, W, False), L("-64,-30 -24,8", 18, W, False))


# --- Interface icons ------------------------------------------------------------------------------------

def speaker(f=BLUE):
    return [R(60, 196, 90, 120, 26, f), P("130,196 270,90 270,422 130,316", f, True, 24)]


UI = {
    "dash": lambda: [
        E(142, 196, 92, 38, W, -24), E(112, 254, 88, 34, W, -6), E(124, 312, 70, 30, W, 12),
        shoe(292, 300, 0.98),
        L("36,410 112,410", 24, CYAN), L("60,462 150,462", 24, CYAN)],
    "power": lambda: [crystal(256, 250, 1.06), question(256, 244, 0.86)],
    "gem": lambda: crystal(256, 250, 1.08, BLUES),
    "coin": lambda: [C(256, 256, 190, GOLD), C(256, 256, 140, YELLOW, False), star(256, 262, 92, GOLD, False), shine(176, 164, 44, 18)],
    "trophy": lambda: [
        K("M140 130 C50 130 60 270 170 270", 40, GOLD), K("M372 130 C462 130 452 270 342 270", 40, GOLD),
        R(226, 300, 60, 90, 16, GOLD), R(150, 380, 212, 72, 26, BROWN),
        D("M120 70 H392 V190 C392 280 330 330 256 330 C182 330 120 280 120 190 Z", YELLOW),
        star(256, 180, 62, GOLD, False), shine(168, 124, 16, 40, 8)],
    "star": lambda: [star(256, 270, 214), shine(170, 196, 34, 16, -40)],
    "gear": lambda: [
        [R(216, 42, 80, 110, 24, GRAY, a) if a == 0 else G(f"rotate({a} 256 256)", R(216, 42, 80, 110, 24, GRAY)) for a in range(0, 360, 45)],
        C(256, 256, 156, GRAY), C(256, 256, 62, DPURPLE, False), shine(186, 180, 34, 14)],
    "chat": lambda: [
        D("M120 80 H392 C450 80 480 120 480 170 V270 C480 320 450 360 392 360 H250 L140 450 L156 360 H120 C62 360 32 320 32 270 V170 C32 120 62 80 120 80 Z", W),
        C(152, 220, 32, DPURPLE, False), C(256, 220, 32, DPURPLE, False), C(360, 220, 32, DPURPLE, False)],
    "guild": lambda: [
        L("256,180 256,50", 24, DGRAY), P("262,44 380,86 262,124", RED, True, 14),
        R(116, 200, 280, 250, 26, PURPLE),
        R(100, 168, 74, 86, 18, PURPLE), R(219, 168, 74, 86, 18, PURPLE), R(338, 168, 74, 86, 18, PURPLE),
        D("M206 450 V360 C206 300 306 300 306 360 V450 Z", DPURPLE, False)],
    "shop": lambda: [
        R(80, 210, 352, 240, 26, CREAM),
        R(120, 270, 110, 180, 18, BLUE, 0, False), R(266, 270, 130, 100, 18, CYAN, 0, False),
        D("M84 80 H428 L478 196 C478 250 400 250 400 208 C400 250 310 250 310 208 C310 250 202 250 202 208 C202 250 112 250 112 208 C112 250 34 250 34 196 Z", RED),
        D("M154 80 H220 L202 208 C202 250 112 250 112 208 Z", W, False), D("M292 80 H358 L400 208 C400 250 310 250 310 208 Z", W, False)],
    "avatar": lambda: person(256, 250, 1.75),
    "map": lambda: [
        P("60,130 180,80 330,130 452,80 452,382 330,432 180,382 60,432", "#ffe39a", True, 20),
        P("180,80 330,130 330,432 180,382", "#ffd06a", False, 0),
        K("M110 350 C150 260 210 330 260 260", 18, DRED, False), L("316,180 386,250", 26, RED, False), L("386,180 316,250", 26, RED, False)],
    "rank": lambda: [
        P("120,50 220,50 300,210 200,240", BLUE, True, 18), P("392,50 292,50 212,210 312,240", DBLUE, True, 18),
        C(256, 320, 136, GOLD), C(256, 320, 98, YELLOW, False), star(256, 326, 66, GOLD, False)],
    "play": lambda: [P("150,90 420,256 150,422", GREEN, True, 60), shine(186, 186, 16, 40, 8)],
    "crown": lambda: [
        P("70,160 164,250 256,90 348,250 442,160 402,400 110,400", YELLOW, True, 30), R(108, 356, 296, 62, 24, GOLD, 0, False),
        C(70, 150, 32, RED), C(256, 82, 36, BLUE), C(442, 150, 32, RED), C(256, 300, 30, PINK, False)],
    "shield": lambda: [
        D("M256 50 C320 90 380 100 430 100 C440 270 380 400 256 462 C132 400 72 270 82 100 C132 100 192 90 256 50 Z", BLUE),
        D("M256 94 V416 C160 362 118 262 122 134 C170 130 216 118 256 94 Z", DBLUE, False), star(256, 250, 80, W, False)],
    "flag": lambda: [L("130,462 130,56", 32, BROWN), D("M136 70 C230 30 300 120 410 76 V270 C300 320 230 226 136 262 Z", RED), C(130, 50, 26, YELLOW)],
    "cage": lambda: [
        K("M96 440 V210 C96 40 416 40 416 210 V440", 34, GRAY),
        L("176,432 176,110", 26, GRAY), L("256,432 256,84", 26, GRAY), L("336,432 336,110", 26, GRAY),
        R(70, 410, 372, 50, 25, DGRAY), L("100,260 412,260", 26, GRAY)],
    "back": lambda: arrow("M440 256 H180", "230,110 76,256 230,402", 86, BLUE),
    "arrow_left": lambda: L("310,90 150,256 310,422", 84, W),
    "arrow_right": lambda: L("202,90 362,256 202,422", 84, W),
    "sound": lambda: [speaker(), K("M326 186 C366 226 366 286 326 326", 34, CYAN), K("M384 124 C458 200 458 312 384 388", 34, CYAN)],
    "mute": lambda: [speaker(GRAY), L("342,196 452,316", 38, RED), L("452,196 342,316", 38, RED)],
    "music": lambda: [
        P("176,126 412,66 412,110 176,170", PINK, True, 18), L("190,140 190,370", 32, PINK), L("398,90 398,330", 32, PINK),
        E(142, 376, 64, 50, PINK, -18), E(350, 336, 64, 50, PINK, -18)],
    "help": lambda: [C(256, 256, 200, BLUE), shine(170, 150, 44, 18), question(250, 244, 1.25, W, False)],
    "emote": lambda: [
        C(256, 256, 200, YELLOW), E(186, 204, 28, 42, BLACK, 0, False), E(326, 204, 28, 42, BLACK, 0, False),
        D("M146 288 H366 C366 388 300 410 256 410 C212 410 146 388 146 288 Z", DRED, False),
        E(256, 372, 58, 28, PINK, 0, False), C(178, 192, 11, W, False), C(318, 192, 11, W, False)],
    "hat": lambda: [
        P("256,56 420,430 92,430", PINK, True, 30), C(256, 52, 40, YELLOW),
        P("226,180 288,180 320,256 190,256", YELLOW, False, 0), P("160,330 354,330 386,410 124,410", BLUE, False, 0)],
    "trail": lambda: [
        K("M60 420 C150 410 200 360 240 280", 44, PURPLE, True, 0.55), star(330, 170, 124, YELLOW), C(120, 300, 26, CYAN), C(60, 230, 18, PINK), spark(430, 330, 52, W, True)],
    "aura": lambda: [
        K("M256 76 A180 180 0 1 1 255 76 Z", 44, PURPLE), K("M256 76 A180 180 0 0 1 436 256", 44, PINK, False),
        person(256, 280, 0.9, BLUE), spark(96, 116, 56, YELLOW, True), spark(420, 410, 46, CYAN, True)],
    "burst": lambda: [star(256, 256, 216, ORANGE, True, -90, 8, 0.62), star(256, 256, 126, YELLOW, False, -68, 8, 0.6), C(256, 256, 40, W, False)],
    "frame": lambda: [R(64, 64, 384, 384, 70, GOLD), R(128, 128, 256, 256, 40, BLUE, 0, False), star(256, 260, 90, YELLOW, False), shine(108, 100, 34, 13, -40)],
    "title": lambda: [
        P("40,230 130,200 130,380 40,380 76,306", DBLUE, True, 16), P("472,230 382,200 382,380 472,380 436,306", DBLUE, True, 16),
        R(96, 130, 320, 170, 34, BLUE), star(256, 214, 58, YELLOW, False)],
    "dance": lambda: [
        L("256,30 256,110", 18, GRAY), C(256, 270, 164, CYAN),
        [L(f"{92 + 54 * i},150 {92 + 54 * i},400", 8, W, False, 0.8) for i in range(1, 6)], [L(f"100,{170 + 50 * i} 412,{170 + 50 * i}", 8, W, False, 0.8) for i in range(0, 5)],
        spark(70, 120, 58, YELLOW, True), spark(444, 180, 44, PINK, True), spark(452, 420, 34, W, True)],
    "backpack": lambda: [
        K("M186 120 C186 50 326 50 326 120", 28, DBROWN), R(100, 110, 312, 348, 76, ORANGE), R(150, 270, 212, 136, 34, YELLOW, 0, False), L("150,206 362,206", 16, DRED, False)],
    "skull": lambda: [
        D("M256 50 C390 50 450 140 450 230 C450 310 400 340 376 352 V430 H136 V352 C112 340 62 310 62 230 C62 140 122 50 256 50 Z", W),
        E(174, 240, 54, 62, BLACK, 0, False), E(338, 240, 54, 62, BLACK, 0, False), P("256,296 286,350 226,350", BLACK, False, 6),
        L("212,394 212,430", 14, BLACK, False), L("256,394 256,430", 14, BLACK, False), L("300,394 300,430", 14, BLACK, False)],
    "robot": lambda: [
        L("256,120 256,60", 22, DGRAY), C(256, 54, 28, YELLOW), R(70, 220, 40, 110, 18, GOLD), R(402, 220, 40, 110, 18, GOLD),
        R(92, 120, 328, 300, 80, GRAY), R(136, 180, 240, 124, 50, BLACK, 0, False), C(198, 242, 34, CYAN, False), C(314, 242, 34, CYAN, False), R(186, 346, 140, 26, 13, DGRAY, 0, False)],
    "exit": lambda: [R(90, 56, 220, 400, 34, BROWN), C(262, 266, 18, YELLOW, False), arrow("M226 256 H390", "372,150 480,256 372,362", 62, GREEN)],
    "lock": lambda: [K("M154 240 V170 C154 40 358 40 358 170 V240", 48, GRAY), R(86, 220, 340, 240, 60, YELLOW), R(86, 400, 340, 60, 30, GOLD, 0, False), C(256, 314, 38, DBROWN, False), R(238, 320, 36, 74, 16, DBROWN, 0, False)],
    "mask": lambda: [
        D("M40 180 C120 120 200 150 256 190 C312 150 392 120 472 180 C486 300 390 380 300 350 C280 342 268 310 256 310 C244 310 232 342 212 350 C122 380 26 300 40 180 Z", PURPLE),
        E(152, 240, 60, 40, BLACK, 12, False), E(360, 240, 60, 40, BLACK, -12, False), star(256, 130, 60, YELLOW), shine(104, 186, 28, 12)],
    "top": lambda: [
        P("170,70 342,70 462,160 400,258 360,226 360,444 152,444 152,226 112,258 50,160", RED, True, 40),
        K("M196 74 C196 136 316 136 316 74", 22, DRED, False), star(256, 290, 62, W, False)],
    "pants": lambda: [
        P("110,90 402,90 442,420 296,420 256,244 216,420 70,420", BLUE, True, 40), R(102, 72, 308, 62, 18, DBLUE, 0, True), L("244,134 244,196", 12, DBLUE, False)],
    "shoes": lambda: shoe(256, 276, 1.25, RED),
    "gloves": lambda: [
        R(150, 380, 212, 84, 30, W), E(256, 226, 158, 172, RED), E(112, 228, 58, 86, RED, -20), shine(204, 120, 54, 20), E(280, 300, 86, 26, DRED, 0, False)],
    "people": lambda: [person(120, 280, 1.05, BLUE, "#c98a58"), person(392, 280, 1.05, GREEN, "#e8b07a", "#5a2b1a"), person(256, 250, 1.3, RED)],
    "gift": lambda: [
        K("M256 150 C170 30 90 90 170 150", 32, RED), K("M256 150 C342 30 422 90 342 150", 32, RED),
        R(76, 230, 360, 222, 30, PURPLE), R(52, 146, 408, 104, 28, DPURPLE), R(220, 146, 72, 306, 0, YELLOW, 0, False)],
    "swords": lambda: [
        G("rotate(45 256 256)", R(226, 20, 60, 340, 24, GRAY), P("226,40 256,0 286,40", GRAY, True, 8), R(166, 340, 180, 42, 20, GOLD), R(232, 380, 48, 90, 20, BROWN)),
        G("rotate(-45 256 256)", R(226, 20, 60, 340, 24, CREAM), P("226,40 256,0 286,40", CREAM, True, 8), R(166, 340, 180, 42, 20, GOLD), R(232, 380, 48, 90, 20, BROWN))],
    "check": lambda: L("90,270 206,386 424,130", 90, GREEN),
    "close": lambda: [L("116,116 396,396", 90, RED), L("396,116 116,396", 90, RED)],
    "plus": lambda: [L("256,96 256,416", 92, GREEN), L("96,256 416,256", 92, GREEN)],
    "pause": lambda: [R(112, 80, 104, 352, 40, W), R(296, 80, 104, 352, 40, W)],
    "search": lambda: [L("326,326 440,440", 62, BROWN), C(218, 218, 160, CYAN), shine(166, 152, 44, 18)],
    "menu": lambda: [R(70, 86, 372, 76, 38, W), R(70, 218, 372, 76, 38, W), R(70, 350, 372, 76, 38, W)],
    "paw": lambda: [
        E(256, 330, 126, 110, ORANGE), E(106, 232, 50, 66, ORANGE, -20), E(204, 138, 52, 70, ORANGE, -6), E(308, 138, 52, 70, ORANGE, 6), E(406, 232, 50, 66, ORANGE, 20),
        E(256, 346, 70, 58, "#ffd8a8", 0, False)],
    "globe": lambda: [
        C(256, 256, 204, BLUE),
        D("M120 150 C150 96 240 90 270 130 C290 170 240 190 214 180 C196 230 150 250 124 216 C106 196 106 170 120 150 Z", GREEN, False, 6),
        D("M300 230 C350 200 420 230 430 290 C430 360 370 420 320 400 C296 350 270 290 300 230 Z", GREEN, False, 6),
        D("M150 310 C180 300 210 330 200 370 C190 400 170 410 150 390 C136 370 136 330 150 310 Z", GREEN, False, 6),
        shine(170, 110, 50, 18, -30)],
    "w_sun": lambda: [
        [G(f"rotate({a} 256 256)", R(232, 26, 48, 96, 24, ORANGE)) for a in range(0, 360, 45)],
        C(256, 256, 130, YELLOW), shine(204, 200, 34, 14)],
    "w_fog": lambda: [
        cloud(256, 160, 1.0, CREAM), R(76, 262, 360, 44, 22, W), R(120, 330, 280, 44, 22, W), R(60, 398, 320, 44, 22, W)],
    "w_night": lambda: [
        D("M322 60 C210 60 110 150 110 270 C110 390 210 462 322 462 C380 462 430 440 462 400 C340 420 254 360 254 256 C254 168 310 96 396 76 C372 64 348 60 322 60 Z", YELLOW),
        star(380, 200, 44, W), star(330, 310, 26, W)],
    "w_rain": lambda: [
        cloud(256, 170, 1.15, W),
        [E(x, y, 22, 44, BLUE, 20) for x, y in [(130, 342), (256, 372), (382, 342), (190, 444), (322, 444)]]],
    "w_storm": lambda: [cloud(256, 160, 1.2, "#8fa0c8"), bolt(250, 340, 1.2), [E(x, 400, 18, 36, BLUE, 20) for x in (110, 392)]],
    "w_snow": lambda: [
        [G(f"rotate({a} 256 256)", R(232, 50, 48, 412, 24, CYAN), R(166, 102, 48, 110, 22, CYAN, -40), R(298, 102, 48, 110, 22, CYAN, 40)) for a in (0, 60, 120)],
        C(256, 256, 44, W)],
    "w_hail": lambda: [cloud(256, 170, 1.15, "#c8d8f0"), C(140, 360, 44, CYAN), C(256, 420, 50, W), C(376, 356, 44, CYAN), shine(240, 400, 14, 8)],
    "w_wind": lambda: [
        K("M50 170 H300 C400 170 400 60 310 70", 42, CYAN), K("M50 270 H380 C470 270 470 390 370 370", 42, W), K("M50 370 H210 C290 370 290 470 214 450", 42, CYAN)],
    "w_sand": lambda: [
        K("M60 150 H340 C420 150 420 70 350 80", 38, "#e6c387"), K("M60 250 H420", 38, ORANGE), K("M60 350 H300 C380 350 380 440 310 430", 38, "#e6c387"),
        C(420, 340, 22, ORANGE), C(460, 180, 16, ORANGE), C(100, 440, 18, ORANGE)],
    "w_heat": lambda: [
        C(256, 180, 120, ORANGE), C(256, 180, 80, YELLOW, False),
        K("M120 360 C150 330 170 390 200 360 C230 330 250 390 280 360 C310 330 330 390 360 360 C380 340 396 350 400 360", 26, RED),
        K("M120 440 C150 410 170 470 200 440 C230 410 250 470 280 440 C310 410 330 470 360 440 C380 420 396 430 400 440", 26, ORANGE)],
    "w_ash": lambda: [
        P("70,450 200,190 312,190 442,450", BROWN, True, 22), P("200,190 312,190 340,250 286,290 240,246 172,250", RED, False, 6),
        flame(256, 110, 0.7), C(100, 180, 26, ORANGE), C(420, 150, 22, ORANGE)],
    "w_meteor": lambda: [
        K("M440 70 L230 250", 54, ORANGE), K("M360 60 L210 200", 30, YELLOW), K("M450 150 L300 280", 30, YELLOW), C(170, 320, 110, BROWN), C(146, 296, 26, DBROWN, False), C(206, 354, 18, DBROWN, False)],
    "w_blossom": lambda: [
        [G(f"rotate({a} 256 256)", E(256, 130, 80, 112, "#ffc2dc")) for a in range(0, 360, 72)],
        C(256, 256, 50, YELLOW), C(256, 256, 22, ORANGE, False)],
}


# --- What's on each power's card ---------------------------------------------------------------------------

POWER = {
    # Speed
    "rocket_slippers": lambda: [
        flame(86, 322, 0.62), shoe(290, 300, 0.92, RED, BLUE), P("176,214 110,180 126,270", YELLOW, True, 10), spark(420, 130, 46)],
    "blink_step": lambda: [
        E(146, 400, 118, 42, PURPLE), E(146, 400, 74, 22, DPURPLE, 0, False), E(366, 130, 118, 42, CYAN), E(366, 130, 74, 22, BLUE, 0, False),
        arrow("M170 340 C180 250 240 210 318 206", "292,146 382,200 302,264", 34, W)],
    "super_hop": lambda: [
        L("176,392 336,352 176,312 336,272 176,232 336,192", 38, GRAY), R(120, 120, 272, 66, 33, RED), R(106, 394, 300, 70, 35, DGRAY), shine(170, 142, 34, 10, 0)],
    "grapple_vine": lambda: [
        K("M80 450 C170 340 80 180 240 140 C310 120 372 130 410 170", 38, DGREEN), E(146, 330, 58, 28, LEAF, -35), E(190, 190, 58, 28, LEAF, 20),
        K("M410 170 C452 250 386 310 340 260", 36, GRAY)],
    "tailwind": lambda: [
        cloud(170, 170, 0.86), K("M60 300 H330 C410 300 410 200 340 206", 40, CYAN), K("M60 390 H250 C330 390 330 480 262 462", 36, CYAN), spark(442, 396, 44)],
    "ghost_sprint": lambda: [
        L("36,210 110,210", 26, CYAN), L("20,290 96,290", 26, CYAN), L("44,370 118,370", 26, CYAN), ghost(300, 270, 1.35, PURPLE)],
    "home_run": lambda: [
        R(136, 230, 240, 220, 26, CREAM), P("256,60 450,250 62,250", RED, True, 26), D("M212 450 V350 C212 300 300 300 300 350 V450 Z", BLUE, False), heart(256, 172, 0.42, W, False)],
    "coco_boost": lambda: [
        L("322,170 386,56", 26, GREEN), C(250, 310, 158, BROWN), E(250, 188, 112, 36, CREAM, 0, False), bolt(250, 320, 0.86), shine(150, 256, 16, 36, 20)],
    # Attack
    "freeze_ray": lambda: [
        [G(f"rotate({a} 256 256)", L("256,56 256,456", 42, CYAN), L("206,104 256,154 306,104", 28, CYAN), L("206,408 256,358 306,408", 28, CYAN)) for a in (0, 60, 120)],
        C(256, 256, 56, W), spark(430, 90, 36)],
    "coconut_shot": lambda: [
        L("34,190 124,190", 26, W), L("20,280 110,280", 26, W), L("44,370 134,370", 26, W), C(310, 274, 152, BROWN),
        E(360, 210, 66, 54, CREAM, 30, False), C(254, 252, 16, DBROWN, False), C(300, 310, 16, DBROWN, False), C(240, 330, 14, DBROWN, False)],
    "fishing_net": lambda: [
        L("176,322 74,454", 44, BROWN), C(300, 196, 158, "#e7f7ff"),
        [L(f"{170 + 60 * i},70 {170 + 60 * i},326", 10, DBLUE, False) for i in range(5)], [L(f"150,{86 + 56 * i} 450,{86 + 56 * i}", 10, DBLUE, False) for i in range(5)],
        K("M300 38 A158 158 0 1 1 299 38 Z", 32, GOLD)],
    "slime_ball": lambda: [
        D("M256 60 C380 60 460 160 460 270 C460 340 430 350 420 400 C414 450 366 450 352 406 C340 370 316 370 306 410 C296 470 226 470 216 410 C206 366 176 366 160 396 C140 440 92 430 92 380 C92 340 52 330 52 270 C52 160 132 60 256 60 Z", LEAF),
        E(190, 216, 30, 44, BLACK, 0, False), E(322, 216, 30, 44, BLACK, 0, False), C(178, 200, 11, W, False), C(310, 200, 11, W, False), shine(138, 136, 44, 18)],
    "sky_zap": lambda: [cloud(256, 150, 1.25, GRAY), bolt(256, 340, 1.3)],
    "thunderstorm": lambda: [
        cloud(256, 150, 1.32, DGRAY), bolt(170, 360, 0.9), bolt(330, 370, 0.9), L("70,300 50,350", 18, CYAN), L("250,310 234,356", 18, CYAN), L("450,300 430,350", 18, CYAN)],
    "shockwave": lambda: [
        K("M256 36 A220 220 0 1 1 255 36 Z", 30, CYAN), K("M256 106 A150 150 0 1 1 255 106 Z", 30, W), C(256, 256, 72, ORANGE), C(256, 256, 34, YELLOW, False)],
    "big_magnet": lambda: [
        K("M136 170 V270 C136 430 376 430 376 270 V170", 96, RED), R(84, 70, 104, 110, 18, GRAY), R(324, 70, 104, 110, 18, GRAY),
        spark(256, 110, 54, YELLOW, True)],
    "mini_twister": lambda: [
        E(256, 106, 190, 52, GRAY), E(244, 192, 146, 46, W), E(268, 272, 106, 40, GRAY), E(240, 344, 70, 32, W), E(262, 412, 38, 26, GRAY), shine(170, 96, 44, 12, 0)],
    "black_hole": lambda: [
        E(256, 256, 216, 96, DPURPLE, -24), E(256, 256, 170, 66, ORANGE, -24, False), E(256, 256, 130, 44, YELLOW, -24, False), C(256, 256, 96, BLACK), spark(420, 96, 40), spark(90, 410, 30)],
    "rolling_barrel": lambda: [
        L("36,200 100,200", 24, W), L("22,300 86,300", 24, W), R(112, 80, 300, 360, 90, BROWN), R(98, 156, 328, 44, 22, GRAY, 0, False), R(98, 322, 328, 44, 22, GRAY, 0, False),
        L("212,90 212,430", 12, DBROWN, False), L("312,90 312,430", 12, DBROWN, False)],
    "ricochet_disc": lambda: [
        arrow("M60 430 L190 330 L300 410 L410 280", "366,262 452,226 440,322", 28, W), E(226, 190, 178, 90, ORANGE), E(226, 172, 112, 50, YELLOW, 0, False), shine(160, 150, 40, 12, -10)],
    "hot_trail": lambda: [flame(366, 276, 1.3), flame(190, 356, 0.8, RED), flame(80, 410, 0.45, RED)],
    "earthquake": lambda: [
        R(40, 240, 432, 212, 52, BROWN), R(40, 240, 432, 62, 30, LEAF, 0, False),
        P("240,240 300,240 262,310 310,350 268,452 214,452 244,366 204,322", INK, False, 2), R(90, 120, 80, 70, 22, GRAY, -20), R(350, 90, 70, 62, 20, GRAY, 20), R(260, 150, 48, 44, 14, GRAY, 12)],
    "meteor_shower": lambda: [
        D("M180 240 L410 40 L360 200 L470 170 L280 370 Z", ORANGE), D("M210 270 L370 120 L330 240 L400 226 L290 330 Z", YELLOW, False),
        C(180, 330, 118, "#8a6a5a"), C(146, 306, 24, "#6a4c40", False), C(214, 360, 20, "#6a4c40", False), C(90, 110, 26, ORANGE), C(50, 200, 18, YELLOW)],
    "giant_growth": lambda: [
        person(130, 370, 0.58, BLUE), person(320, 250, 1.5, RED), arrow("M80 250 V96", "28,136 80,44 132,136", 30, GREEN)],
    "overcharge": lambda: [
        R(210, 40, 92, 60, 18, DGRAY), R(116, 84, 280, 376, 56, GRAY), R(150, 220, 212, 208, 30, GREEN, 0, False), bolt(256, 266, 1.1)],
    "chain_tag": lambda: [
        G("rotate(-38 256 256)", K("M80 186 H190 C250 186 250 326 190 326 H80 C20 326 20 186 80 186 Z", 40, GRAY), K("M322 186 H432 C492 186 492 326 432 326 H322 C262 326 262 186 322 186 Z", 40, GRAY), L("190,256 322,256", 40, GOLD)),
        bolt(400, 106, 0.5)],
    # Defend
    "bubble_shield": lambda: [
        C(256, 256, 206, "#bff3ff"), D("M256 130 C296 156 336 162 366 162 C372 270 336 340 256 384 C176 340 140 270 146 162 C176 162 216 156 256 130 Z", BLUE, False),
        E(160, 136, 52, 22, W, -38, False, 0.85), C(376, 366, 16, W, False, 0.8)],
    "popup_wall": lambda: [
        R(54, 320, 192, 110, 22, ORANGE), R(266, 320, 192, 110, 22, ORANGE), R(160, 196, 192, 110, 22, RED), R(54, 72, 192, 110, 22, ORANGE), R(266, 72, 192, 110, 22, ORANGE),
        R(30, 196, 112, 110, 22, ORANGE), R(370, 196, 112, 110, 22, ORANGE)],
    "base_lock": lambda: [K("M162 236 V176 C162 56 350 56 350 176 V236", 46, GRAY), R(92, 216, 328, 236, 58, YELLOW), R(92, 396, 328, 56, 28, GOLD, 0, False), star(256, 316, 62, ORANGE, False)],
    "sentry_buddy": lambda: [
        L("256,120 256,62", 20, DGRAY), C(256, 56, 26, RED), R(104, 118, 304, 236, 74, GRAY), C(256, 226, 72, BLACK, False), C(256, 226, 42, RED, False), C(240, 210, 13, W, False),
        R(404, 196, 80, 50, 22, DGRAY), R(120, 348, 110, 92, 40, DGRAY), R(282, 348, 110, 92, 40, DGRAY)],
    "snare_ring": lambda: [
        K("M410 110 C480 40 500 170 420 190", 26, BROWN), E(256, 330, 200, 104, BROWN), E(256, 322, 140, 62, "#6a4c40", 0, False),
        [P(f"{256 + math.cos(math.radians(a)) * 170:.0f},{326 + math.sin(math.radians(a)) * 84:.0f} {256 + math.cos(math.radians(a)) * 128:.0f},{290 + math.sin(math.radians(a)) * 62:.0f} {256 + math.cos(math.radians(a + 22)) * 170:.0f},{326 + math.sin(math.radians(a + 22)) * 84:.0f}", GRAY, False, 4) for a in range(0, 360, 40)]],
    "pop_mines": lambda: [
        [G(f"rotate({a} 256 276)", R(232, 84, 48, 80, 20, DGRAY)) for a in range(0, 360, 45)], C(256, 276, 150, BLACK), C(256, 276, 50, RED, False), shine(196, 208, 34, 14)],
    "slow_dome": lambda: [
        P("130,76 382,76 280,256 382,436 130,436 232,256", "#e7f7ff", True, 24), P("164,110 348,110 288,206 224,206", YELLOW, False, 8), P("256,290 340,420 172,420", YELLOW, False, 8),
        R(92, 44, 328, 62, 30, BROWN), R(92, 406, 328, 62, 30, BROWN)],
    "thorn_hedge": lambda: [
        [P(f"{x},{y} {x2},{y2} {x3},{y3}", CREAM, True, 6) for x, y, x2, y2, x3, y3 in [(90, 180, 26, 110, 140, 130), (250, 90, 256, 16, 310, 90), (420, 170, 490, 110, 372, 130), (450, 330, 500, 390, 420, 380), (60, 340, 10, 390, 96, 390)]],
        C(150, 290, 118, GREEN), C(360, 290, 118, GREEN), C(256, 200, 132, LEAF), R(60, 320, 392, 120, 50, GREEN)],
    "mirror_shield": lambda: [
        R(226, 350, 60, 124, 26, BROWN), E(256, 216, 166, 190, GOLD), E(256, 216, 122, 146, CYAN, 0, False), P("170,300 300,110 336,140 206,330", W, False, 8, 0.8), spark(424, 68, 48, W, True)],
    "fresh_start": lambda: [
        arrow("M412 280 C400 420 170 460 90 300 C50 200 130 96 240 90", "208,30 310,90 208,150", 50, GREEN), spark(256, 266, 92, YELLOW, True)],
    # Trick
    "switcheroo": lambda: [
        arrow("M90 170 C160 100 300 100 370 170", "332,84 436,206 306,216", 44, RED), arrow("M422 342 C352 412 212 412 142 342", "180,428 76,306 206,296", 44, BLUE)],
    "stale_curse": lambda: [
        K("M120 450 C60 390 170 370 110 300", 26, GREEN, True, 0.8), K("M400 450 C460 390 350 370 410 300", 26, GREEN, True, 0.8),
        D("M256 44 C374 44 420 126 420 204 C420 276 376 300 356 310 V370 H156 V310 C136 300 92 276 92 204 C92 126 138 44 256 44 Z", PURPLE),
        E(186, 210, 46, 54, BLACK, 0, False), E(326, 210, 46, 54, BLACK, 0, False), C(186, 222, 16, LEAF, False), C(326, 222, 16, LEAF, False), P("256,262 280,306 232,306", BLACK, False, 4)],
    "squid_ink": lambda: [
        [K(f"M{x} 300 C{x + d} 360 {x - d} 400 {x + d} 462", 40, PINK) for x, d in [(130, -16), (210, 14), (302, -14), (382, 16)]],
        D("M256 34 C330 90 400 180 400 268 C400 340 330 350 256 350 C182 350 112 340 112 268 C112 180 182 90 256 34 Z", PINK),
        C(196, 240, 44, W, False), C(316, 240, 44, W, False), C(204, 246, 24, BLACK, False), C(308, 246, 24, BLACK, False), E(256, 312, 26, 18, DRED, 0, False)],
    "mixup_hex": lambda: [
        K("M256 256 C256 216 320 216 320 266 C320 340 192 340 192 256 C192 140 390 140 390 276 C390 410 134 420 124 250", 44, PURPLE),
        star(90, 110, 54), star(430, 100, 42, CYAN), star(430, 420, 36, PINK)],
    "soap_slick": lambda: [
        R(70, 180, 300, 200, 70, PINK, -14), R(116, 216, 200, 120, 50, "#ff9fd0", -14, False), C(380, 150, 64, "#bff3ff"), C(440, 280, 34, "#bff3ff"), C(240, 100, 38, "#bff3ff"), C(362, 134, 14, W, False), C(228, 88, 9, W, False)],
    "scare_horn": lambda: [
        R(50, 190, 150, 170, 44, RED), R(76, 150, 100, 52, 18, GRAY), P("190,226 370,110 370,430 190,316", YELLOW, True, 20), E(380, 270, 34, 164, GOLD),
        K("M430 176 C470 230 470 310 430 364", 22, CYAN, False)],
    "decoy_squad": lambda: [ghost(110, 300, 0.7, BLUE, True), ghost(402, 300, 0.7, PINK, True), person(256, 270, 1.5, RED)],
    "invisi_cloak": lambda: [
        D("M180 86 C216 56 296 56 332 86 C400 180 430 340 450 440 C380 410 360 450 320 420 C290 450 222 450 192 420 C152 450 132 410 62 440 C82 340 112 180 180 86 Z", DPURPLE),
        E(256, 132, 62, 44, BLACK, 0, False), E(232, 130, 8, 13, W, 0, False), E(280, 130, 8, 13, W, 0, False), spark(120, 170, 44, YELLOW, True), spark(404, 220, 36, W, True), spark(256, 320, 40, CYAN, False)],
    "ghost_mode": lambda: [ghost(256, 270, 1.75), E(166, 170, 30, 14, W, -30, False, 0.9)],
    "tiny_time": lambda: [
        C(136, 170, 92, GRAY), C(376, 170, 92, GRAY), C(136, 170, 52, PINK, False), C(376, 170, 52, PINK, False), E(256, 300, 158, 138, GRAY),
        E(204, 276, 21, 30, BLACK, 0, False), E(308, 276, 21, 30, BLACK, 0, False), E(256, 342, 26, 18, PINK, 0, False)],
    "jailbreak": lambda: [
        L("110,60 110,450", 42, GRAY), L("402,60 402,450", 42, GRAY), L("256,60 256,150", 42, GRAY), L("256,360 256,450", 42, GRAY), R(70, 36, 372, 52, 26, DGRAY), R(70, 424, 372, 52, 26, DGRAY),
        star(256, 256, 110, ORANGE, True, -90, 8, 0.55), star(256, 256, 60, YELLOW, False, -68, 8, 0.55)],
    # Team
    "fiesta_rush": lambda: [
        K("M26 110 C150 190 362 190 486 110", 16, BROWN), P("56,140 136,172 78,256", RED, True, 12), P("156,178 248,186 192,288", YELLOW, True, 12), P("262,186 354,178 318,288", BLUE, True, 12), P("374,172 456,140 432,256", GREEN, True, 12),
        star(166, 390, 44, PINK), star(350, 410, 34, CYAN), C(256, 356, 20, ORANGE)],
    "team_refresh": lambda: [
        arrow("M90 250 C90 120 300 50 400 180", "340,160 440,230 460,120", 40, GOLD), arrow("M422 272 C422 402 212 462 112 332", "172,352 72,282 52,392", 40, GOLD), heart(256, 262, 0.82, GREEN)],
    "group_hug": lambda: [heart(256, 256, 2.1), person(170, 340, 0.62, BLUE), person(342, 340, 0.62, GREEN, "#e8b07a"), shine(150, 134, 48, 20, -40)],
    "radar_ping": lambda: [
        C(256, 256, 206, DGREEN), D("M256 256 L256 50 A206 206 0 0 1 434 154 Z", LEAF, False, 0), K("M256 116 A140 140 0 1 1 255 116 Z", 12, LEAF, False), K("M256 186 A70 70 0 1 1 255 186 Z", 12, LEAF, False),
        C(340, 180, 24, YELLOW, False), C(170, 322, 18, RED, False), C(256, 256, 18, W, False)],
    "capture_boost": lambda: [
        L("140,470 140,56", 32, BROWN), D("M146 70 C220 40 280 110 372 74 V236 C280 280 220 206 146 236 Z", RED), arrow("M360 450 V336", "304,356 360,272 416,356", 34, GREEN)],
    "power_rain": lambda: [
        cloud(256, 140, 1.25, W), crystal(120, 340, 0.27), crystal(256, 418, 0.27, BLUES), crystal(392, 340, 0.27, [PINK, YELLOW, GREEN, CYAN, ORANGE, RED, PURPLE])],
    # World collection
    "magic_carpet": lambda: [
        D("M40 300 C110 250 180 340 256 300 C330 250 400 340 472 290 L472 380 C400 430 330 340 256 390 C180 430 110 340 40 390 Z", RED),
        D("M90 330 C140 310 190 370 256 340 C320 310 370 370 430 330 L430 352 C370 396 320 332 256 362 C190 396 140 330 90 356 Z", YELLOW, False, 2),
        L("40,410 20,450", 16, YELLOW), L("100,420 84,460", 16, YELLOW), L("472,400 492,440", 16, YELLOW), cloud(390, 130, 0.5), star(130, 150, 36)],
    "human_cannon": lambda: [
        G("rotate(-30 200 330)", R(70, 260, 280, 140, 60, GRAY), R(320, 244, 44, 172, 20, DGRAY)), C(120, 420, 62, BROWN), C(120, 420, 28, DBROWN, False),
        person(390, 170, 0.62, RED), L("296,270 330,240", 18, YELLOW), star(250, 120, 30)],
    "moon_boots": lambda: [
        C(150, 140, 90, CREAM), C(120, 118, 20, "#e6d8a8", False), C(176, 168, 14, "#e6d8a8", False),
        G("translate(40 40)", shoe(256, 330, 0.9, W, GRAY)), star(420, 120, 34), star(340, 70, 22, W)],
    "turbo_skates": lambda: [
        shoe(280, 240, 0.92, PINK, W), C(160, 380, 46, YELLOW), C(280, 380, 46, YELLOW), C(400, 380, 46, YELLOW),
        C(160, 380, 18, DGRAY, False), C(280, 380, 18, DGRAY, False), C(400, 380, 18, DGRAY, False), L("20,250 90,250", 24, CYAN), L("10,320 70,320", 24, CYAN)],
    "buddy_warp": lambda: [
        person(150, 300, 0.92, BLUE), person(370, 240, 0.92, RED), arrow("M180 150 C230 70 310 70 340 110", "298,72 372,110 322,172", 30, PURPLE), spark(250, 420, 40, CYAN), spark(440, 420, 30, PURPLE)],
    "rewind": lambda: [
        C(256, 256, 190, W), C(256, 256, 150, CYAN, False), L("256,256 256,150", 26, BLACK, False), L("256,256 180,290", 26, BLACK, False),
        arrow("M70 140 C110 70 170 40 230 40", "70,66 30,170 130,158", 30, PURPLE)],
    "mega_wave": lambda: [
        K("M60 256 H470", 170, CYAN), K("M60 256 H470", 90, W, False), C(90, 256, 110, BLUE), C(90, 256, 70, CYAN, False), C(90, 256, 34, W, False),
        spark(340, 100, 44, YELLOW), spark(420, 410, 40, YELLOW), spark(210, 430, 28, W)],
    "homing_missile": lambda: [
        G("rotate(-38 256 256)", P("140,180 70,120 70,250", RED, True, 10), P("140,332 70,262 70,392", RED, True, 10),
          R(110, 190, 270, 132, 60, CREAM), P("370,190 480,256 370,322", RED, True, 22), C(306, 256, 34, CYAN), flame(66, 256, 0.45)),
        L("70,90 130,60", 16, GRAY), K("M420 80 A44 44 0 1 1 419 80 Z", 14, RED), C(420, 124, 12, RED, False)],
    "boomerang": lambda: [
        D("M90 400 C60 240 170 90 340 70 C420 64 450 130 400 160 C300 170 210 270 200 420 C200 480 110 470 90 400 Z", ORANGE),
        D("M130 390 C110 260 200 130 350 100 C380 96 396 120 380 136 C280 150 180 260 170 400 C160 430 136 420 130 390 Z", YELLOW, False, 2),
        arrow("M440 280 C450 360 380 430 320 440", "356,380 280,448 370,484", 22, CYAN)],
    "giant_snowball": lambda: [
        C(290, 250, 180, W), C(236, 190, 24, CYAN, False), C(350, 280, 34, CYAN, False), C(260, 340, 22, CYAN, False),
        C(90, 390, 50, W), C(40, 440, 28, W), shine(220, 130, 50, 20), L("70,250 120,250", 22, CYAN)],
    "anvil_drop": lambda: [
        L("110,50 110,110", 20, CYAN), L("256,30 256,90", 20, CYAN), L("400,50 400,110", 20, CYAN),
        D("M110 150 H400 V190 C350 200 330 230 330 270 H390 V330 H130 V270 H190 C190 230 160 200 110 190 Z", GRAY),
        E(256, 430, 170, 36, BLACK, 0, False, 0.5), star(106, 420, 34), star(410, 420, 34)],
    "cream_pie": lambda: [
        P("70,300 440,300 390,440 120,440", "#d9a066", True, 20), E(256, 290, 192, 90, W), E(180, 230, 70, 54, W), E(310, 220, 84, 70, W), E(250, 170, 56, 46, W),
        C(256, 124, 36, RED), K("M256 96 C270 60 300 50 320 60", 12, DGREEN, False)],
    "angry_bees": lambda: [
        G("translate(256 276) rotate(-12)", E(-34, -116, 78, 60, CYAN, -30, True, 0.9), E(46, -116, 78, 60, CYAN, 30, True, 0.9), E(0, 0, 164, 118, YELLOW),
          R(-46, -114, 56, 228, 0, BLACK, 0, False), R(66, -94, 50, 190, 0, BLACK, 0, False), E(-104, -26, 18, 26, BLACK, 0, False), K("M-140 -56 L-94 -44", 14, BLACK, False)),
        G("translate(90 110) scale(0.26)", E(0, 0, 164, 118, YELLOW)), G("translate(430 120) scale(0.22)", E(0, 0, 164, 118, YELLOW))],
    "rain_cloud": lambda: [
        cloud(256, 150, 1.15, "#8fa0c8"), E(186, 150, 14, 22, BLACK, 0, False), E(326, 150, 14, 22, BLACK, 0, False), K("M220 216 C240 190 272 190 292 216", 12, BLACK, False),
        E(160, 320, 22, 44, BLUE, 12), E(256, 360, 22, 44, BLUE, 12), E(352, 320, 22, 44, BLUE, 12), person(256, 470, 0.34, RED)],
    "tidal_wave": lambda: [
        D("M20 470 C60 300 140 120 300 70 C400 40 480 110 470 180 C430 130 360 130 320 190 C390 170 440 220 450 300 C460 380 480 430 492 470 Z", BLUE),
        D("M300 70 C400 40 480 110 470 180 C430 130 360 130 320 190 C280 150 280 100 300 70 Z", W, False, 4),
        C(120, 300, 24, CYAN, False), C(190, 200, 18, CYAN, False), person(92, 430, 0.34, RED)],
    "dragon_breath": lambda: [
        flame(350, 256, 0.92), flame(220, 256, 0.66), flame(120, 256, 0.44),
        star(440, 110, 30, YELLOW), star(450, 410, 22, YELLOW)],
    "meteor_slam": lambda: [
        K("M420 40 L280 240", 50, ORANGE), K("M370 40 L270 190", 26, YELLOW), person(254, 256, 0.72, RED),
        star(256, 440, 130, ORANGE, True, -90, 8, 0.5), star(256, 440, 70, YELLOW, False, -68, 8, 0.5)],
    "chain_lightning": lambda: [
        C(70, 110, 44, RED), C(250, 240, 44, BLUE), C(420, 130, 44, GREEN), C(350, 410, 44, PINK),
        L("100,130 180,170 170,200 228,226", 26, YELLOW), L("280,226 340,180 350,210 394,150", 26, YELLOW), L("264,282 310,320 290,350 336,378", 26, YELLOW)],
    "shrink_ray": lambda: [
        G("rotate(-20 200 200)", R(50, 150, 240, 100, 40, PURPLE), R(280, 170, 70, 60, 16, GRAY), C(120, 200, 26, CYAN, False), R(100, 240, 66, 110, 24, DGRAY)),
        L("370,200 440,170", 22, YELLOW), L("380,250 460,250", 22, YELLOW), L("370,300 440,330", 22, YELLOW), person(420, 420, 0.3, RED)],
    "bubble_trap": lambda: [
        C(256, 256, 190, CYAN, True, 0.55), person(256, 290, 0.74, RED), C(160, 170, 30, W, False, 0.8), E(176, 136, 16, 8, W, -30, False, 0.9), C(430, 110, 34, CYAN), C(70, 410, 26, CYAN)],
    "cannonball": lambda: [
        C(280, 256, 170, BLACK), C(220, 190, 30, GRAY, False), K("M60 170 H150", 28, CYAN), K("M30 256 H110", 28, CYAN), K("M60 340 H150", 28, CYAN), star(450, 120, 34), star(470, 400, 26)],
    "hot_potato": lambda: [
        E(256, 300, 170, 130, "#d9a066"), C(190, 280, 16, BROWN, False), C(300, 340, 12, BROWN, False), C(330, 260, 14, BROWN, False),
        E(214, 270, 16, 24, BLACK, 0, False), E(300, 270, 16, 24, BLACK, 0, False), K("M222 340 C246 310 266 310 290 340", 12, BLACK, False),
        K("M256 180 C256 110 310 110 340 80", 20, GRAY), flame(360, 60, 0.3)],
    "instant_igloo": lambda: [
        D("M60 400 C60 180 180 90 256 90 C332 90 452 180 452 400 Z", "#eaf6ff"),
        D("M200 400 C200 300 312 300 312 400 Z", BLACK, False, 2), K("M90 300 H422", 12, CYAN, False), K("M130 210 H382", 12, CYAN, False), L("256,90 256,210", 12, CYAN, False),
        L("176,210 176,300", 12, CYAN, False), L("336,210 336,300", 12, CYAN, False), spark(450, 90, 36, W)],
    "guardian_angel": lambda: [
        E(116, 250, 110, 56, W, -25), E(396, 250, 110, 56, W, 25), E(150, 300, 80, 40, CYAN, -20), E(362, 300, 80, 40, CYAN, 20),
        person(256, 300, 0.76, RED), K("M180 96 A76 26 0 1 1 332 96 A76 26 0 1 1 180 96", 18, YELLOW)],
    "orbit_shields": lambda: [
        K("M36 256 A220 90 0 1 1 476 256 A220 90 0 1 1 36 256", 12, CYAN, False), person(256, 250, 0.74, RED),
        C(64, 256, 50, CYAN), C(420, 170, 50, YELLOW), C(380, 350, 50, PINK), shine(50, 240, 12, 8), shine(406, 154, 12, 8)],
    "robo_buddy": lambda: [
        L("256,110 256,60", 18, DGRAY), C(256, 50, 24, RED), R(110, 110, 292, 200, 70, CYAN), R(146, 150, 220, 110, 40, BLACK, 0, False), C(206, 204, 30, YELLOW, False), C(306, 204, 30, YELLOW, False),
        R(150, 320, 212, 90, 40, GRAY), C(180, 430, 36, DGRAY), C(332, 430, 36, DGRAY), L("420,190 480,140", 20, GRAY), bolt(470, 90, 0.3)],
    "stop_clock": lambda: [
        K("M186 60 H326", 46, RED), R(226, 66, 60, 60, 12, GRAY), C(256, 280, 190, W), C(256, 280, 152, CYAN, False), L("256,280 256,170", 26, BLACK, False), L("256,280 340,330", 26, BLACK, False), C(256, 280, 22, BLACK, False),
        spark(68, 120, 40, CYAN), spark(450, 130, 34, CYAN)],
    "smoke_bomb": lambda: [
        cloud(150, 180, 0.92, "#d7d2ff"), cloud(350, 150, 0.82, "#efeaff"), C(256, 340, 110, BLACK), C(216, 300, 22, GRAY, False), K("M300 250 C320 200 360 190 390 210", 18, BROWN), spark(400, 214, 36, YELLOW)],
    "ninja_clones": lambda: [
        G("translate(110 260) scale(0.72)", C(0, 0, 130, BLACK, True, 0.5), R(-110, -30, 220, 56, 28, CREAM, 0, False, 0.5)),
        G("translate(400 260) scale(0.72)", C(0, 0, 130, BLACK, True, 0.5), R(-110, -30, 220, 56, 28, CREAM, 0, False, 0.5)),
        C(256, 250, 150, BLACK), R(126, 206, 260, 70, 34, CREAM, 0, False), C(206, 242, 20, BLACK, False), C(306, 242, 20, BLACK, False),
        R(130, 130, 252, 34, 17, RED, 0, False), K("M380 150 C420 170 430 210 460 200", 18, RED, False)],
    "banana_peels": lambda: [
        D("M256 240 C210 300 120 340 70 420 C130 410 210 390 262 320 C300 390 360 420 440 430 C400 350 310 300 256 240 Z", YELLOW),
        D("M240 240 C220 170 240 110 276 80 C300 130 290 190 272 240 Z", YELLOW), R(240, 64, 40, 34, 10, DBROWN), L("120,180 170,130", 18, CYAN), star(390, 180, 32)],
    "chicken_curse": lambda: [
        E(256, 320, 150, 130, W), C(256, 170, 96, W), P("330,160 410,180 330,200", ORANGE, True, 12), C(290, 150, 16, BLACK, False),
        C(226, 66, 28, RED), C(266, 58, 30, RED), C(304, 72, 26, RED), E(340, 216, 18, 34, RED, 0),
        E(130, 310, 66, 40, CREAM, -25), L("220,440 220,486", 20, ORANGE), L("296,440 296,486", 20, ORANGE), spark(80, 110, 40, PURPLE), spark(450, 340, 30, PURPLE)],
    "dance_fever": lambda: [
        L("256,10 256,70", 14, DGRAY), C(256, 150, 90, CYAN), [C(256 + x, 150 + y, 14, c, False) for x, y, c in [(-44, -30, PINK), (30, -50, W), (0, 0, YELLOW), (50, 24, PINK), (-40, 40, W), (10, 60, YELLOW)]],
        person(160, 390, 0.5, RED), person(352, 390, 0.5, BLUE), [spark(x, y, 26, c) for x, y, c in [(70, 260, YELLOW), (450, 240, PINK), (256, 310, W)]]],
    "lullaby": lambda: [
        D("M322 80 C232 80 150 160 150 256 C150 352 232 430 322 430 C374 430 416 410 446 370 C350 390 280 330 280 256 C280 180 340 120 412 110 C390 92 356 80 322 80 Z", YELLOW),
        L("70,110 130,110 70,180 130,180", 20, CYAN), L("170,60 210,60 170,106 210,106", 16, CYAN), star(420, 250, 26, W)],
    "portal_pair": lambda: [
        E(110, 300, 80, 150, ORANGE), E(110, 300, 46, 110, BLACK, 0, False), E(402, 200, 80, 150, BLUE), E(402, 200, 46, 110, BLACK, 0, False),
        arrow("M170 240 C220 150 280 140 330 170", "290,110 366,170 296,222", 26, W)],
    "fake_crystal": lambda: [
        crystal(256, 220, 0.98), L("256,300 256,370", 22, GRAY), C(256, 410, 58, RED), star(256, 412, 38, YELLOW, False), K("M160 110 L100 60", 20, W), K("M360 110 L420 60", 20, W)],
    "pickpocket": lambda: [
        R(150, 120, 170, 240, 24, CREAM), R(174, 148, 122, 180, 12, PURPLE, 0, False), star(235, 236, 44, YELLOW, False),
        D("M300 400 C230 400 200 370 220 340 C260 330 330 340 350 320 C400 300 450 340 450 400 Z", "#e8b07a"), K("M340 340 C400 300 430 270 440 220", 44, "#e8b07a"), spark(90, 170, 36)],
    "wild_card": lambda: [
        G("rotate(-16 200 280)", R(90, 120, 200, 290, 26, PURPLE), star(190, 266, 60, YELLOW, False)),
        G("rotate(14 330 260)", R(230, 90, 200, 290, 26, W), question(330, 230, 0.8, RED, False)), spark(70, 90, 36), spark(450, 420, 36, CYAN)],
    "copycat": lambda: [
        C(256, 280, 170, ORANGE), P("100,190 112,60 210,130", ORANGE, True, 16), P("412,190 400,60 302,130", ORANGE, True, 16),
        E(196, 260, 24, 36, BLACK, 0, False), E(316, 260, 24, 36, BLACK, 0, False), P("240,320 272,320 256,342", PINK, False, 6),
        K("M216 370 C236 390 256 380 256 350 C256 380 276 390 296 370", 10, BLACK, False), L("90,300 40,284", 10, BLACK, False), L("422,300 472,284", 10, BLACK, False)],
    "rally_call": lambda: [
        P("80,200 240,120 240,392 80,312", RED, True, 24), R(40, 196, 70, 120, 20, GRAY), K("M280 150 C340 200 340 312 280 362", 30, YELLOW), K("M350 100 C440 180 440 332 350 412", 30, YELLOW),
        person(140, 440, 0.3, BLUE), person(250, 460, 0.3, GREEN)],
    "crystal_vacuum": lambda: [
        R(310, 280, 160, 170, 40, RED), K("M330 320 C230 300 170 270 130 210", 54, GRAY), P("60,150 180,100 200,220", GRAY, True, 12), crystal(70, 70, 0.24), crystal(230, 70, 0.2, BLUES), crystal(380, 130, 0.2),
        C(350, 420, 34, DGRAY), C(450, 420, 34, DGRAY)],
    "cheer_squad": lambda: [
        C(150, 230, 88, PINK), C(362, 230, 88, YELLOW), R(226, 200, 60, 200, 26, GRAY), star(256, 150, 80, ORANGE),
        spark(70, 90, 34), spark(440, 90, 34), L("120,340 90,430", 28, BLUE), L("392,340 422,430", 28, BLUE)],
    "weather_machine": lambda: [
        R(90, 200, 332, 240, 40, GRAY), C(256, 320, 84, W), L("256,320 300,270", 18, RED, False), C(130, 240, 18, YELLOW, False), C(382, 240, 18, GREEN, False),
        cloud(170, 110, 0.62, W), bolt(330, 110, 0.6), L("180,440 180,490", 24, DGRAY), L("332,440 332,490", 24, DGRAY)],
}

CATS = {"speed": ("#5fe39c", "#1a9c58"), "attack": ("#ff7f6e", "#c9302a"), "defend": ("#6cc0ff", "#1a6fd0"),
        "trick": ("#cc93ff", "#7f38d6"), "team": ("#ffd65c", "#e48f0a")}
RIM = {1: "#ffffff", 2: "#c8e8ff", 3: "#ffe14d"}


def svg(width, height, view, inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view}">{inner}</svg>\n'


def rays(cx, cy, reach, count=10, colour="#ffffff", opacity=0.13):
    out = []
    for i in range(count):
        a = math.tau * i / count
        b = a + math.pi / count
        out.append(f'<polygon points="{cx},{cy} {cx + math.cos(a) * reach:.1f},{cy + math.sin(a) * reach:.1f} {cx + math.cos(b) * reach:.1f},{cy + math.sin(b) * reach:.1f}" fill="{colour}" opacity="{opacity}"/>')
    return "".join(out)


def card(art, cat, tier):
    top, low = CATS[cat]
    rim = RIM[tier]
    stars = "".join(f'<g transform="translate({30 + i * 26} 34) scale(0.052)">{body(star(0, 0, 214, "#ffd23f"))}</g>' for i in range(tier))
    sparkle = ""
    if tier == 3:
        sparkle = "".join(f'<g transform="translate({x} {y}) scale({s})">{body(spark(0, 0, 100, "#fff8c4"))}</g>' for x, y, s in [(204, 40, 0.2), (42, 214, 0.14), (198, 206, 0.12)])
    return svg(240, 320, "0 0 240 320", (
        f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{low}"/></linearGradient>'
        '<clipPath id="p"><rect x="20" y="20" width="200" height="212" rx="18"/></clipPath></defs>'
        f'<rect x="2" y="4" width="236" height="314" rx="30" fill="{INK}"/>'
        f'<rect x="8" y="8" width="224" height="302" rx="25" fill="url(#g)" stroke="{rim}" stroke-width="4"/>'
        '<rect x="20" y="20" width="200" height="212" rx="18" fill="#ffffff" opacity="0.26"/>'
        f'<g clip-path="url(#p)">{rays(120, 126, 190)}</g>'
        f'<g transform="translate(32 40) scale(0.344)">{body(art)}</g>'
        f'<rect x="14" y="238" width="212" height="66" rx="16" fill="{INK}" opacity="0.9"/>'
        f"{stars}{sparkle}"
    ))


def card_back():
    return svg(240, 320, "0 0 240 320", (
        '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a5cff"/><stop offset="1" stop-color="#4a23b8"/></linearGradient></defs>'
        f'<rect x="2" y="4" width="236" height="314" rx="30" fill="{INK}"/>'
        '<rect x="8" y="8" width="224" height="302" rx="25" fill="url(#g)" stroke="#ffffff" stroke-width="4"/>'
        '<rect x="22" y="22" width="196" height="274" rx="16" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.4"/>'
        f"{rays(120, 160, 190, 12)}"
        f'<g transform="translate(26 66) scale(0.367)">{body(crystal(256, 250, 1.06), question(256, 244, 0.86))}</g>'
    ))


def main():
    ui_dir = ROOT / "assets/icons/ui"
    power_dir = ROOT / "assets/icons/power"
    ui_dir.mkdir(parents=True, exist_ok=True)
    power_dir.mkdir(parents=True, exist_ok=True)
    for name, draw in UI.items():
        (ui_dir / f"{name}.svg").write_text(svg(160, 160, "0 0 512 512", body(draw())), encoding="utf-8")
    db = (ROOT / "core/data/Powerups.gd").read_text(encoding="utf-8")
    defs = {m.group(1): (m.group(2), int(m.group(3))) for m in re.finditer(r'"id": "(\w+)", "name": "[^"]+", "cat": "(\w+)", "tier": (\d)', db)}
    missing = set(defs) - set(POWER)
    extra = set(POWER) - set(defs)
    if missing or extra:
        raise SystemExit(f"cards don't match the powers. No art for {sorted(missing)}; art for no power: {sorted(extra)}")
    for name, (cat, tier) in defs.items():
        (power_dir / f"{name}.svg").write_text(card(POWER[name](), cat, tier), encoding="utf-8")
    (power_dir / "_back.svg").write_text(card_back(), encoding="utf-8")
    # Anything else in there is left over from an older set of icons.
    for folder, keep in ((ui_dir, set(UI)), (power_dir, set(defs) | {"_back"})):
        for old in folder.glob("*.svg"):
            if old.stem not in keep:
                print("left over, not used:", old.name)
    print(f"{len(UI)} icons, {len(defs)} cards")


if __name__ == "__main__":
    main()
