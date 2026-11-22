#!/usr/bin/env python3
"""Imports Rok's recorded voice line (the "time to run!" shout, rok_alarm).

Drop the recording in ../Assets/Rok_Voice/ named rok_alarm.<wav|m4a|mp3|aiff|caf>
(any format macOS afconvert reads), then:
    python3 tools/prepare_voice.py            # standard library only, macOS
    godot --headless --path . --import

It converts the clip to 22.05 kHz mono 16-bit like every other sound, trims
the silence at both ends (keeping a few ms), adds short fades so it doesn't
click, normalises the peak and writes assets/sounds/rok_alarm.wav. The game
plays it at the run start and on hunter charges (scripts/main.gd); until the
file exists it's silent.

Options: --src FILE / --out FILE override the paths; --gain DB adjusts the
level after normalising.
"""
import argparse
import array
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT.parent / "Assets" / "Rok_Voice"
OUT = ROOT / "assets" / "sounds" / "rok_alarm.wav"
SR = 22050
EXTS = [".wav", ".m4a", ".mp3", ".aiff", ".aif", ".caf"]


def find_source():
    for ext in EXTS:
        p = SRC_DIR / f"rok_alarm{ext}"
        if p.exists():
            return p
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--gain", type=float, default=0.0)
    a = ap.parse_args()
    src = a.src or find_source()
    if src is None or not src.exists():
        sys.exit(f"No recording found: put rok_alarm.<{'|'.join(e[1:] for e in EXTS)}> in {SRC_DIR}")
    with tempfile.TemporaryDirectory() as tmp:
        conv = Path(tmp) / "conv.wav"
        subprocess.run(["afconvert", "-f", "WAVE", "-d", f"LEI16@{SR}", "-c", "1", str(src), str(conv)], check=True)
        with wave.open(str(conv)) as w:
            x = array.array("h", w.readframes(w.getnframes()))
    if not x:
        sys.exit("The recording is empty")
    peak = max(abs(v) for v in x) or 1
    # trim: first/last sample above 4% of the peak, keeping 15 ms around it
    thr = peak * 0.04
    loud = [i for i, v in enumerate(x) if abs(v) > thr]
    keep = int(SR * 0.015)
    lo, hi = max(0, loud[0] - keep), min(len(x), loud[-1] + keep)
    y = [float(v) for v in x[lo:hi]]
    # 5 ms fades, then normalise to 90% (plus --gain)
    f = min(int(SR * 0.005), len(y) // 2)
    for i in range(f):
        y[i] *= i / f
        y[-1 - i] *= i / f
    scale = 0.9 * 32767 / (max(abs(v) for v in y) or 1) * 10 ** (a.gain / 20)
    out = array.array("h", (max(-32768, min(32767, int(v * scale))) for v in y))
    a.out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(a.out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(out.tobytes())
    print(f"{src.name} -> {a.out} ({len(out) / SR:.2f} s)")


if __name__ == "__main__":
    main()
