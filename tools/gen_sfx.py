"""Makes the game's silliest sounds from nothing: nobody else's recordings, so nothing to license. Needs numpy, scipy and ffmpeg.

    python tools/gen_sfx.py

Writes assets/audio/sfx/*.ogg. Godot needs an --import after that.
"""
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parent.parent
RATE = 22050
rng = np.random.default_rng(11)


def times(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def low(signal, cutoff):
    return sosfilt(butter(2, cutoff, "low", fs=RATE, output="sos"), signal)


def band(signal, lo, hi):
    return sosfilt(butter(2, [lo, hi], "band", fs=RATE, output="sos"), signal)


def saw(pitch):
    """A rough buzzy wave whose pitch can change as it goes."""
    phase = np.cumsum(pitch) / RATE
    return 2.0 * (phase % 1.0) - 1.0


def sine(pitch):
    return np.sin(2.0 * np.pi * np.cumsum(pitch) / RATE)


def fade(signal, attack=0.01, release=0.05):
    n = len(signal)
    a = max(int(attack * RATE), 1)
    r = max(int(release * RATE), 1)
    env = np.ones(n)
    env[:a] = np.linspace(0.0, 1.0, a)
    env[-r:] = np.minimum(env[-r:], np.linspace(1.0, 0.0, r))
    return signal * env


def flutter(n, speed, depth=1.0):
    """Slow noise, for things that aren't quite steady."""
    points = max(int(n / RATE * speed), 2)
    return np.interp(np.arange(n), np.linspace(0, n, points), rng.uniform(-depth, depth, points))


def fart(seconds, start, end):
    t = times(seconds)
    n = len(t)
    pitch = np.linspace(start, end, n) * (1.0 + 0.32 * flutter(n, 26))
    buzz = saw(pitch)
    gate = 0.65 + 0.35 * np.sign(np.sin(2.0 * np.pi * np.cumsum(np.linspace(26, 15, n)) / RATE))  # The flapping that makes it what it is.
    wet = flutter(n, 700, 0.3) * np.abs(flutter(n, 12))
    sound = low(buzz * gate, 900.0) + wet
    swell = np.minimum(t / 0.05, 1.0) * (1.0 - 0.55 * t / seconds)
    return fade(sound * swell, 0.01, 0.07)


def squelch():
    t = times(0.34)
    n = len(t)
    pitch = np.linspace(480, 90, n) + 60 * np.sin(t * 70)
    wet = band(rng.normal(0.0, 1.0, n), 250, 1400) * np.exp(-t * 11) * 0.9
    return fade(low(saw(pitch), 1300) * np.exp(-t * 7) + wet, 0.004, 0.05)


def burp():
    t = times(0.85)
    n = len(t)
    pitch = (92 - 34 * t / 0.85) * (1.0 + 0.2 * flutter(n, 30))
    throat = saw(pitch)
    wobble = 480 + 170 * np.sin(t * 9.0)
    voice = band(throat, 200, 900) + 0.6 * band(throat, 700, 1500) * (wobble / 650)
    return fade(voice * np.minimum(t / 0.05, 1.0), 0.02, 0.16)


def sneeze():
    t1 = times(0.34)
    build = band(saw(np.linspace(240, 430, len(t1))), 300, 1500) * np.linspace(0.3, 0.8, len(t1))
    t2 = times(0.42)
    blast = band(rng.normal(0.0, 1.0, len(t2)), 1200, 6500) * np.exp(-t2 * 9) * 2.6
    return np.concatenate([fade(build, 0.03, 0.03), np.zeros(int(0.03 * RATE)), fade(blast, 0.003, 0.08)])


def moo():
    t = times(1.05)
    n = len(t)
    pitch = np.interp(t, [0, 0.25, 1.05], [118, 142, 96]) * (1.0 + 0.012 * np.sin(t * 34))
    throat = saw(pitch)
    open_up = np.interp(t, [0, 0.3, 1.05], [0.25, 1.0, 0.7])
    voice = band(throat, 200, 650) + open_up * 0.8 * band(throat, 700, 1250)
    return fade(voice, 0.09, 0.2)


def honk():
    t = times(0.26)
    pitch = np.interp(t, [0, 0.07, 0.26], [800, 1500, 760])
    return fade(np.tanh(3.0 * sine(pitch)) + 0.5 * np.tanh(3.0 * sine(pitch * 1.34)), 0.005, 0.05)


def slide_whistle():
    t = times(0.78)
    pitch = np.interp(t, [0, 0.42, 0.78], [520, 1750, 700]) * (1.0 + 0.012 * np.sin(t * 40))
    return fade(sine(pitch) + 0.12 * sine(pitch * 2.0), 0.02, 0.07)


def giggle():
    out = []
    for i, base in enumerate([880, 980, 1100, 1040, 1240]):
        t = times(0.085)
        pitch = np.linspace(base, base * 1.2, len(t))
        out.append(fade(sine(pitch) + 0.5 * saw(pitch * 0.5), 0.006, 0.03))
        out.append(np.zeros(int(0.045 * RATE)))
    return np.concatenate(out)


SOUNDS = {
    "fart_short": lambda: fart(0.36, 118, 88),
    "fart_long": lambda: fart(1.15, 72, 128),
    "squelch": squelch,
    "burp": burp,
    "sneeze": sneeze,
    "moo": moo,
    "honk": honk,
    "slide_whistle": slide_whistle,
    "giggle": giggle,
}


def main():
    out_dir = ROOT / "assets/audio/sfx"
    with tempfile.TemporaryDirectory() as scratch:
        for name, make in SOUNDS.items():
            sound = make()
            sound = (sound / max(np.abs(sound).max(), 1e-6) * 0.82 * 32767).astype(np.int16)
            wav = Path(scratch) / f"{name}.wav"
            wavfile.write(wav, RATE, sound)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "3", str(out_dir / f"{name}.ogg")], check=True)
            print(name, f"{len(sound) / RATE:.2f}s", (out_dir / f"{name}.ogg").stat().st_size, "bytes")


if __name__ == "__main__":
    main()
