#!/usr/bin/env python3
"""Synthesises every sound in assets/sounds (no external audio needed).

Usage (needs numpy):  python3 tools/make_sounds.py
Writes 22.05 kHz mono 16-bit WAVs: sound effects plus a ~40 s looping
prehistoric/tribal music track (toms, shaker, woodblock, bass, marimba, flute).
"""
import wave
from pathlib import Path

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ helpers

def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.005, decay=None, release=0.02):
    """Linear attack, exponential decay (seconds to -60 dB), linear release."""
    e = np.ones(n)
    a = max(1, int(SR * attack))
    e[:a] = np.linspace(0, 1, a)
    if decay:
        k = np.arange(n - a) / SR
        e[a:] *= np.power(10.0, -3.0 * k / decay)
    r = min(n, max(1, int(SR * release)))
    e[-r:] *= np.linspace(1, 0, r)
    return e


def sweep(f0, f1, dur, shape=np.sin, curve=1.0):
    t = t_axis(dur)
    f = f0 + (f1 - f0) * (t / dur) ** curve
    ph = 2 * np.pi * np.cumsum(f) / SR
    return shape(ph)


def tri(ph):
    return 2 / np.pi * np.arcsin(np.sin(ph))


def saw(ph):
    return 2 * ((ph / (2 * np.pi)) % 1.0) - 1


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array (per sample)."""
    cut = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * cut / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def pad(x, dur):
    return np.concatenate([x, np.zeros(int(SR * dur))])


def write(name, x, peak=0.9):
    x = np.asarray(x, dtype=float)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    data = (x * 32767).astype("<i2").tobytes()
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def note_hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# ------------------------------------------------------------------ sfx

def sfx():
    # jump: soft rising "boing"
    j = sweep(260, 620, 0.16, curve=0.7) * env(int(SR * 0.16), 0.004, 0.25)
    write("jump", j, 0.7)
    # double jump: higher sweep + sparkle
    dj = sweep(480, 1150, 0.16, curve=0.6) * env(int(SR * 0.16), 0.003, 0.2)
    sp = sum(np.sin(2 * np.pi * f * t_axis(0.22)) * env(int(SR * 0.22), 0.001, 0.12)
             for f in (2093, 2637))
    write("double_jump", mix(dj, pad(np.zeros(int(SR * 0.04)), 0)[:0], np.concatenate([np.zeros(int(SR * 0.05)), sp * 0.3])), 0.65)
    # land: dull thud
    n = int(SR * 0.12)
    th = lowpass(noise(0.12), 400) * env(n, 0.001, 0.08) * 3 + sweep(120, 50, 0.12) * env(n, 0.001, 0.1)
    write("land", th, 0.6)
    # shift: whoosh (noise with rising cutoff) + shimmer
    d = 0.55
    n = int(SR * d)
    cut = np.linspace(300, 5000, n) ** 1.0
    wh = lowpass(noise(d), cut) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 2.5
    sh = sum(np.sin(2 * np.pi * f * t_axis(d) + 3 * np.sin(2 * np.pi * 6 * t_axis(d)))
             for f in (880, 1320, 1760)) * env(n, 0.15, 0.6) * 0.25
    write("shift", mix(wh, sh), 0.75)
    # form roars / calls
    def roar(f0, f1, dur, grit, vib, bright):
        n = int(SR * dur)
        t = t_axis(dur)
        f = np.linspace(f0, f1, n) * (1 + 0.04 * np.sin(2 * np.pi * vib * t))
        ph = 2 * np.pi * np.cumsum(f) / SR
        body = saw(ph) + 0.5 * saw(ph * 1.01)
        body = lowpass(body, bright)
        g = lowpass(noise(dur), bright * 1.5) * grit
        return (body + g) * env(n, 0.04, dur * 1.6, 0.08)
    write("form_rok", sweep(330, 520, 0.14, tri) * env(int(SR * 0.14), 0.01, 0.2), 0.6)
    write("form_raptor", roar(900, 600, 0.35, 0.6, 18, 3500), 0.6)
    write("form_triceratops", roar(160, 110, 0.45, 0.8, 7, 900), 0.75)
    write("form_spinosaurus", roar(110, 70, 0.7, 1.0, 5, 700), 0.8)
    write("form_pteranodon", mix(roar(1500, 1000, 0.3, 0.35, 22, 5000),
                                 np.concatenate([np.zeros(int(SR * 0.12)), roar(1700, 1300, 0.2, 0.3, 25, 5500)])), 0.55)
    # flap: soft low whoosh of a wingbeat
    d = 0.2
    n = int(SR * d)
    flap = lowpass(noise(d), np.linspace(900, 250, n)) * np.sin(np.linspace(0, np.pi, n)) ** 1.5 * 3.0
    write("flap", flap, 0.5)
    # T-rex: long bellowing roar, heavy stomp, jaw snap
    d = 1.4
    n = int(SR * d)
    t = t_axis(d)
    f = np.interp(t, [0, 0.25, 0.9, 1.4], [70, 120, 95, 55]) * (1 + 0.05 * np.sin(2 * np.pi * 6 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    body = saw(ph) + 0.6 * saw(ph * 1.5) + 0.4 * saw(ph * 2.02)
    body = lowpass(body, np.interp(t, [0, 0.3, 1.4], [500, 1400, 400]))
    growl = lowpass(noise(d), 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t))
    write("trex_roar", (body + growl * 1.2) * env(n, 0.12, 2.2, 0.3), 0.85)
    d = 0.25
    n = int(SR * d)
    write("stomp", (sweep(80, 35, d) * 1.4 + lowpass(noise(d), 300) * 2.0) * env(n, 0.002, 0.18), 0.7)
    d = 0.18
    n = int(SR * d)
    snap = highpass(noise(d), 1500) * env(n, 0.0005, 0.05) + sweep(400, 120, d) * env(n, 0.001, 0.08) * 0.8
    write("bite", snap, 0.8)
    # ---- footsteps per form
    def thump(f0, f1, dur, nz_cut, nz_amt):
        n = int(SR * dur)
        return (sweep(f0, f1, dur) + lowpass(noise(dur), nz_cut) * nz_amt) * env(n, 0.001, dur * 0.7)
    write("step_rok", thump(150, 90, 0.07, 700, 1.2), 0.5)
    d = 0.035
    write("step_raptor", highpass(noise(d), 2200) * env(int(SR * d), 0.0005, 0.02) + sweep(1400, 900, d) * 0.3 * env(int(SR * d), 0.0005, 0.02), 0.45)
    write("step_heavy", thump(75, 34, 0.22, 220, 2.2), 0.8)
    # ---- footsteps per surface
    d = 0.07
    write("step_grass", lowpass(highpass(noise(d), 1400), 3200) * env(int(SR * d), 0.004, 0.05), 0.35)
    d = 0.11
    write("step_sand", lowpass(noise(d), np.linspace(2600, 900, int(SR * d))) * env(int(SR * d), 0.01, 0.09), 0.4)
    d = 0.04
    write("step_rock", mix(highpass(noise(d), 3000) * env(int(SR * d), 0.0005, 0.02), np.sin(2 * np.pi * 820 * t_axis(d)) * 0.4 * env(int(SR * d), 0.0005, 0.03)), 0.45)
    # ---- jumps / landings per form
    d = 0.16
    chirp = sweep(900, 1700, d, curve=0.5) * env(int(SR * d), 0.003, 0.14)
    write("jump_raptor", mix(chirp, np.concatenate([np.zeros(int(SR * 0.05)), sweep(1600, 2200, 0.06) * 0.4 * env(int(SR * 0.06), 0.002, 0.05)])), 0.55)
    d = 0.26
    grunt = lowpass(saw(2 * np.pi * np.cumsum(np.linspace(130, 85, int(SR * d))) / SR), 700) * env(int(SR * d), 0.01, 0.25)
    write("jump_heavy", mix(grunt, thump(90, 45, 0.18, 300, 1.5) * 0.8), 0.7)
    write("land_heavy", mix(thump(70, 28, 0.35, 180, 2.6), lowpass(noise(0.4), 300) * env(int(SR * 0.4), 0.002, 0.3) * 0.8), 0.85)
    # ---- T-rex growl when it closes in
    d = 1.1
    n = int(SR * d)
    t = t_axis(d)
    g = lowpass(saw(2 * np.pi * 52 * t * (1 + 0.03 * np.sin(2 * np.pi * 3 * t))) + 0.6 * saw(2 * np.pi * 78 * t), 500)
    g = g * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * t)) + lowpass(noise(d), 400) * 0.8
    write("trex_growl", g * env(n, 0.15, 1.6, 0.25), 0.8)
    # smash: crunch + thud + debris ticks
    d = 0.45
    n = int(SR * d)
    cr = highpass(noise(d), 800) * env(n, 0.001, 0.18)
    tdd = sweep(140, 40, d) * env(n, 0.001, 0.25) * 1.4
    ticks = np.zeros(n)
    for _ in range(9):
        p = rng.integers(int(SR * 0.05), n - 600)
        ticks[p:p + 500] += highpass(noise(500 / SR), 2000) * env(500, 0.0005, 0.02) * rng.uniform(0.3, 0.7)
    write("smash", mix(cr, tdd, ticks), 0.85)
    # amber chime
    def bell(f, dur, amp=1.0):
        n = int(SR * dur)
        t = t_axis(dur)
        return amp * (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) * env(n, 0.001, dur * 0.3)) * env(n, 0.001, dur)
    am = mix(bell(1318.5, 0.35), np.concatenate([np.zeros(int(SR * 0.07)), bell(1975.5, 0.45)]))
    write("amber", am, 0.55)
    eg = mix(*[np.concatenate([np.zeros(int(SR * 0.07 * i)), bell(f, 0.5)]) for i, f in enumerate((1046.5, 1318.5, 1568, 2093))])
    write("pepper", eg, 0.6)   # the Blaze Pepper power-up (was the Dino Egg)
    # shield: metallic clang + falling tone
    d = 0.6
    n = int(SR * d)
    t = t_axis(d)
    cl = sum(np.sin(2 * np.pi * f * t) * env(n, 0.001, 0.4) for f in (520, 1240, 1890, 2710))
    fall = sweep(900, 300, d) * env(n, 0.01, 0.5) * 0.5
    write("shield", mix(cl * 0.4, fall, highpass(noise(0.05), 2000) * 0.6), 0.7)
    # hit / death: bonk + descending wobble
    d = 0.9
    n = int(SR * d)
    bonk = sweep(300, 90, 0.18) * env(int(SR * 0.18), 0.001, 0.15)
    wob = sweep(500, 120, d, tri, curve=0.8) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t_axis(d))) * env(n, 0.02, 1.0)
    write("hit", mix(bonk * 1.5, np.concatenate([np.zeros(int(SR * 0.1)), wob * 0.6])), 0.8)
    # fall into pit: long descending whistle
    write("fall", sweep(1400, 200, 0.9, curve=0.6) * env(int(SR * 0.9), 0.01, 1.2), 0.5)
    # ui click / denied
    write("click", highpass(noise(0.03), 1500) * env(int(SR * 0.03), 0.0005, 0.02) + sweep(1200, 900, 0.03) * 0.3, 0.5)
    dn = mix(sweep(180, 170, 0.12, saw) * env(int(SR * 0.12), 0.005, 0.3),
             np.concatenate([np.zeros(int(SR * 0.15)), sweep(150, 140, 0.16, saw) * env(int(SR * 0.16), 0.005, 0.3)]))
    write("denied", lowpass(dn, 1200), 0.5)
    # slide: made by slide_sound() (run last, its own rng). These two draws
    # are what the old slide used, kept so the noise of every sound after it
    # stays exactly the same.
    noise(0.5)
    noise(0.5)
    # intro: two soft wooden marimba notes (a "heads up")
    def mar(f, dur):
        n = int(SR * dur)
        t = t_axis(dur)
        return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 4 * t) * env(n, 0.0005, 0.06)) * env(n, 0.001, dur * 0.8)
    write("intro", mix(mar(784, 0.4), np.concatenate([np.zeros(int(SR * 0.12)), mar(1046.5, 0.5)])), 0.6)
    # unlock: rising fanfare arpeggio + horn swell
    notes = (523.25, 659.25, 784.0, 1046.5, 1318.5)
    arp = mix(*[np.concatenate([np.zeros(int(SR * 0.09 * i)), mar(f, 0.7)]) for i, f in enumerate(notes)])
    d = 1.2
    horn = lowpass(saw(2 * np.pi * 261.6 * t_axis(d)) + saw(2 * np.pi * 392 * t_axis(d)), 1800) * env(int(SR * d), 0.25, 2.0, 0.3) * 0.25
    write("unlock", mix(arp, horn), 0.75)
    # start: rising tribal horn
    d = 0.8
    hn = lowpass(saw(2 * np.pi * np.cumsum(np.linspace(196, 262, int(SR * d))) / SR), 1500) * env(int(SR * d), 0.08, 1.5, 0.2)
    write("start", hn, 0.6)


# ------------------------------------------------------------------ music

def music():
    bpm = 100
    beat = 60 / bpm
    bars = 16
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total + SR * 2)

    def place(x, time, gain=1.0):
        i = int(time * SR)
        out[i:i + len(x)] += x[: len(out) - i] * gain

    def tom(f0, f1, dur=0.35):
        n = int(SR * dur)
        return (sweep(f0, f1, dur) + 0.15 * lowpass(noise(dur), 600)) * env(n, 0.002, dur * 0.9)

    def shaker():
        n = int(SR * 0.07)
        return highpass(noise(0.07), 4000) * env(n, 0.01, 0.05)

    def block(f=900):
        n = int(SR * 0.08)
        return (np.sin(2 * np.pi * f * t_axis(0.08)) + 0.3 * highpass(noise(0.08), 3000)) * env(n, 0.0005, 0.05)

    def marimba(m, dur=0.5):
        f = note_hz(m)
        n = int(SR * dur)
        t = t_axis(dur)
        return (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 4 * t) * env(n, 0.0005, 0.08)) * env(n, 0.001, dur * 0.8)

    def bass(m, dur):
        f = note_hz(m)
        n = int(SR * dur)
        ph = 2 * np.pi * f * t_axis(dur)
        return lowpass(tri(ph) + 0.3 * saw(ph), 700) * env(n, 0.005, dur * 1.2, 0.03)

    def flute(m, dur):
        f = note_hz(m)
        n = int(SR * dur)
        t = t_axis(dur)
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5 * t) * np.clip(t / 0.3, 0, 1)
        ph = 2 * np.pi * f * np.cumsum(vib) / SR
        breath = lowpass(noise(dur), 2500) * 0.08
        return (np.sin(ph) + 0.2 * np.sin(2 * ph) + breath) * env(n, 0.08, None, 0.12)

    # A minor pentatonic: A C D E G
    scale = [57, 60, 62, 64, 67, 69, 72, 74, 76, 79]
    chords = [45, 45, 43, 48, 45, 45, 50, 52]  # bass roots per bar (loops twice)
    riff_a = [5, -1, 7, 6, 5, -1, 3, 4, 5, -1, 7, 8, 7, 6, 5, -1]
    riff_b = [7, 8, 9, 8, 7, -1, 5, 6, 7, -1, 5, 4, 3, -1, 4, -1]
    flute_line = [(69, 2), (72, 2), (74, 3), (72, 1), (69, 2), (67, 2), (64, 4),
                  (67, 2), (69, 2), (72, 3), (74, 1), (76, 2), (74, 2), (69, 4)]

    eighth = beat / 2
    for bar in range(bars):
        t0 = bar * beat * 4
        section_b = bar >= 8
        # drums
        for b in range(4):
            tb = t0 + b * beat
            place(tom(95, 55), tb, 0.9 if b in (0, 2) else 0.0)
            if b in (1, 3):
                place(tom(210, 160, 0.2), tb, 0.45)
            if b == 3:
                place(tom(180, 140, 0.18), tb + eighth, 0.35)
        for e in range(8):
            place(shaker(), t0 + e * eighth, 0.18 if e % 2 else 0.1)
        for e in (0, 3, 6):
            place(block(1000 if e else 850), t0 + e * eighth, 0.22)
        if bar % 4 == 3:  # fill
            for k in range(4):
                place(tom(170 - k * 25, 120 - k * 20, 0.2), t0 + 3 * beat + k * beat / 4, 0.4)
        # bass
        root = chords[bar % 8]
        for b, (off, dur) in enumerate([(0, 1.5), (1.5, 0.5), (2, 1), (3, 1)]):
            place(bass(root + (7 if b == 2 else 0), dur * beat), t0 + off * beat, 0.5)
        # marimba riff
        riff = riff_b if section_b else riff_a
        if bar % 2 == 1:
            riff = riff[8:] + riff[:8]
        for i in range(8):
            idx = riff[(bar % 2) * 8 + i]
            if idx >= 0:
                place(marimba(scale[idx]), t0 + i * eighth, 0.32)
    # flute melody over section B
    tf = 8 * beat * 4
    for m, beats in flute_line:
        place(flute(m, beats * beat), tf, 0.22)
        tf += beats * beat

    # fold the tail (reverb-ish decay past the loop end) back to the start
    loop = out[:total].copy()
    tail = out[total:]
    loop[: len(tail)] += tail
    # gentle "room" echo
    d = int(SR * beat * 0.75)
    echo = np.zeros_like(loop)
    echo[d:] = loop[:-d] * 0.18
    echo[:d] += loop[-d:] * 0.18
    write("music", loop + lowpass(echo, 1800), 0.8)


def death_jingle():
    """An original ~2 s 'oh no' jingle: a quick descending marimba run in the
    game's pentatonic scale, a drooping flute note with a sad wobble, and two
    soft drum thumps to close."""
    out = np.zeros(int(SR * 2.4))

    def place(x, t, g=1.0):
        i = int(t * SR)
        out[i:i + len(x)] += x[: len(out) - i] * g

    def mar(m, dur):
        f = note_hz(m)
        n = int(SR * dur)
        t = t_axis(dur)
        return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 4 * t) * env(n, 0.0005, 0.06)) * env(n, 0.001, dur * 0.8)

    # quick tumble down: E5 D5 C5 A4 G4
    for i, m in enumerate([76, 74, 72, 69, 67]):
        place(mar(m, 0.35), i * 0.11, 0.55)
    # drooping flute: starts on E4 and sags a minor third with a slow wobble
    d = 1.0
    t = t_axis(d)
    f = note_hz(64) * (2 ** (-3 / 12 * np.clip((t - 0.25) / 0.7, 0, 1))) * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    flute = (np.sin(ph) + 0.25 * np.sin(2 * ph) + lowpass(noise(d), 2400) * 0.06) * env(int(SR * d), 0.05, 1.6, 0.25)
    place(flute, 0.6, 0.5)
    # two soft thumps: bum, bum
    for i, (f0, f1) in enumerate([(110, 55), (90, 42)]):
        n = int(SR * 0.4)
        thud = (sweep(f0, f1, 0.4) + 0.2 * lowpass(noise(0.4), 500)) * env(n, 0.002, 0.35)
        place(thud, 1.62 + i * 0.26, 0.8)
    write("death_jingle", out, 0.8)


def zone_music(name, bpm, scale, bass_roots, drum, lead_wave, pad_cut, seed):
    """A 16-bar loop in a zone's mood (shared building blocks with music())."""
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    bars = 16
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total + SR * 2)

    def place(x, time, gain=1.0):
        i = int(time * SR)
        out[i:i + len(x)] += x[: len(out) - i] * gain

    def tom(f0, f1, dur=0.35):
        n = int(SR * dur)
        return (sweep(f0, f1, dur) + 0.15 * lowpass(noise(dur), 600)) * env(n, 0.002, dur * 0.9)

    def tek(dur=0.06):
        n = int(SR * dur)
        return highpass(noise(dur), 2500) * env(n, 0.0005, 0.04)

    def pluck(m, dur):
        f = note_hz(m)
        n = int(SR * dur)
        ph = 2 * np.pi * f * t_axis(dur)
        w = saw(ph) if lead_wave == "saw" else tri(ph) + 0.4 * np.sin(2 * ph)
        return lowpass(w, np.linspace(3200, 600, n)) * env(n, 0.002, dur * 0.6)

    def pad(m, dur):
        f = note_hz(m)
        n = int(SR * dur)
        t = t_axis(dur)
        w = saw(2 * np.pi * f * t) + saw(2 * np.pi * f * 1.005 * t)
        return lowpass(w, pad_cut) * env(n, 0.6, None, 0.6)

    eighth = beat / 2
    for bar in range(bars):
        t0 = bar * beat * 4
        root = bass_roots[bar % len(bass_roots)]
        for b in range(4):
            tb = t0 + b * beat
            for (pos, kind, g) in drum:
                if int(pos) == b:
                    tp = tb + (pos - int(pos)) * beat
                    place(tom(95, 50) if kind == "doum" else (tom(220, 170, 0.15) if kind == "mid" else tek()), tp, g)
        place(pad(root + 12, beat * 4), t0, 0.16)
        place(lowpass(tri(2 * np.pi * note_hz(root) * t_axis(beat * 4)), 400) * env(int(SR * beat * 4), 0.01, beat * 6, 0.1), t0, 0.35)
        for i in range(8):
            if r.random() < 0.62:
                place(pluck(scale[r.integers(0, len(scale))] + (12 if bar >= 8 and r.random() < 0.4 else 0), eighth * 1.6), t0 + i * eighth, 0.22)
    loop = out[:total].copy()
    tail = out[total:]
    loop[: len(tail)] += tail
    d = int(SR * beat * 0.75)
    echo = np.zeros_like(loop)
    echo[d:] = loop[:-d] * 0.2
    echo[:d] += loop[-d:] * 0.2
    write(name, loop + lowpass(echo, 1600), 0.8)


def zone_tracks():
    # Desert: E phrygian dominant, hand drums (doum-tek), plucked oud-like lead
    zone_music("music_desert", 92, [64, 65, 68, 69, 71, 72, 74, 76],
               [40, 40, 41, 40, 38, 40, 41, 43],
               [(0, "doum", 0.9), (1, "tek", 0.5), (1.5, "tek", 0.35), (2, "doum", 0.7), (2.5, "mid", 0.4), (3, "tek", 0.5), (3.5, "tek", 0.3)],
               "saw", 900, 11)
    # Volcanic: dark minor ostinato over heavy low drums and a rumbling pad
    zone_music("music_volcanic", 84, [57, 58, 60, 63, 64, 65, 68],
               [33, 33, 34, 33, 31, 33, 34, 29],
               [(0, "doum", 1.0), (0.75, "doum", 0.55), (2, "doum", 0.9), (2.5, "mid", 0.5), (3.5, "mid", 0.5)],
               "tri", 520, 23)


def slide_sound():
    """Rok's slide: a quick downward whoosh as he drops, a soft hip thud on
    contact, then a gritty ground scrape whose friction chatters unevenly,
    with a few pebbles skittering, fading and darkening as he slows down.
    Uses its own rng so it doesn't shift any other sound's noise."""
    r = np.random.default_rng(31)

    def nz(dur):
        return r.uniform(-1, 1, int(SR * dur))

    d = 0.6
    n = int(SR * d)
    t = t_axis(d)
    # 1. the drop: band-passed noise swooping down
    wd = 0.11
    wn = int(SR * wd)
    cut = np.linspace(3800, 900, wn)
    whoosh = highpass(lowpass(nz(wd), cut), cut * 0.45) * env(wn, 0.012, 0.25, 0.03) * 1.6
    # 2. the hip thud as he hits the ground
    td = 0.09
    tn = int(SR * td)
    thud = (sweep(140, 70, td) + lowpass(nz(td), 400) * 0.6) * env(tn, 0.002, 0.12) * 0.9
    thud = np.concatenate([np.zeros(int(SR * 0.05)), thud])
    # 3. the scrape: mid-band grit, its loudness jittering like rough ground
    grain = lowpass(r.uniform(0.35, 1.0, n), 45)   # uneven friction
    fade = np.clip(1 - (t - 0.08) / (d - 0.08), 0, 1) ** 1.4
    rise = np.clip((t - 0.04) / 0.05, 0, 1)
    body = highpass(lowpass(nz(d), np.linspace(2600, 900, n)), 350)
    scrape = body * grain * rise * fade * 2.4
    hiss = highpass(nz(d), 3500) * grain * rise * fade ** 2 * 0.25
    # 4. pebbles: a few short bright ticks scattered along the slide
    ticks = np.zeros(n)
    for _ in range(6):
        at = int(SR * r.uniform(0.07, 0.42))
        kd = 0.012
        k = highpass(nz(kd), 2500) * env(int(SR * kd), 0.0005, 0.01) * r.uniform(0.25, 0.55)
        ticks[at:at + len(k)] += k[: n - at]
    write("slide", mix(whoosh, thud, scrape, hiss, ticks), 0.7)


def break_sounds():
    """Break effects (the user's request, with weapon durability):
    weapon_break (a weapon snapping: a sharp crack, a splintering tear and
    bits clattering down), break_wood (a log or fence giving way: a dry crack,
    creaking splinters and a hollow thump) and break_rock (a rock shattering:
    a hard crunch and rubble tumbling). Their own rng, so no other sound's
    noise shifts."""
    r = np.random.default_rng(57)

    def nz(dur):
        return r.uniform(-1, 1, int(SR * dur))

    def ticks(n, count, t0, t1, cut, dur, lo, hi):
        out = np.zeros(n)
        for _ in range(count):
            at = int(SR * r.uniform(t0, t1))
            k = highpass(nz(dur), cut) * env(int(SR * dur), 0.0005, dur * 0.9) * r.uniform(lo, hi)
            out[at:at + len(k)] += k[: n - at]
        return out

    # weapon_break: crack + splinter tear + a falling clatter
    d = 0.75
    n = int(SR * d)
    crack = highpass(nz(0.03), 1800) * env(int(SR * 0.03), 0.0005, 0.025) * 2.2
    snap = (sweep(900, 180, 0.08, tri) * 0.8 + lowpass(nz(0.08), 1500)) * env(int(SR * 0.08), 0.001, 0.07)
    tear_n = int(SR * 0.22)
    tear = highpass(lowpass(nz(0.22), np.linspace(5000, 1500, tear_n)), 900) * lowpass(r.uniform(0.2, 1.0, tear_n), 60) \
        * env(tear_n, 0.003, 0.2) * 1.3
    clatter = ticks(n, 7, 0.28, 0.68, 1200, 0.025, 0.25, 0.6)
    thunk = np.concatenate([np.zeros(int(SR * 0.3)), (sweep(220, 110, 0.07) + lowpass(nz(0.07), 600) * 0.5) * env(int(SR * 0.07), 0.001, 0.08) * 0.7])
    write("weapon_break", mix(crack, np.concatenate([np.zeros(int(SR * 0.01)), snap]),
                              np.concatenate([np.zeros(int(SR * 0.02)), tear]), clatter, thunk), 0.8)

    # break_wood: dry crack, creaking splinters, hollow thump
    d = 0.55
    n = int(SR * d)
    crack = highpass(nz(0.025), 1500) * env(int(SR * 0.025), 0.0005, 0.02) * 2.0
    creak_n = int(SR * 0.18)
    creak = lowpass(saw(2 * np.pi * np.cumsum(np.linspace(260, 120, creak_n) * (1 + 0.15 * r.uniform(-1, 1, creak_n))) / SR), 1400) \
        * env(creak_n, 0.005, 0.16) * 0.5
    splint = ticks(n, 10, 0.02, 0.32, 2000, 0.012, 0.3, 0.7)
    thump = np.concatenate([np.zeros(int(SR * 0.04)), (sweep(160, 70, 0.12) + lowpass(nz(0.12), 350) * 0.7) * env(int(SR * 0.12), 0.002, 0.14) * 0.9])
    write("break_wood", mix(crack, np.concatenate([np.zeros(int(SR * 0.015)), creak]), splint, thump), 0.8)

    # break_rock: hard crunch and tumbling rubble
    d = 0.7
    n = int(SR * d)
    crunch_n = int(SR * 0.09)
    crunch = (lowpass(nz(0.09), 2600) * 1.4 + sweep(120, 55, 0.09) * 0.9) * env(crunch_n, 0.001, 0.08)
    rubble = ticks(n, 14, 0.05, 0.6, 500, 0.03, 0.2, 0.65)
    rumble = lowpass(nz(d), 220) * env(n, 0.01, 0.4) * 1.2
    write("break_rock", mix(crunch, rubble, rumble), 0.85)


def mumble_sounds():
    """Ugo the merchant's mumble (the user's request: he should sound like he
    mumbles, no words): mumble_1..6, each 2-6 voiced caveman syllables
    ("hm", "bah", "ugh", "oh"...) from a gravelly buzz shaped by two vowel
    formants, a low wobbly pitch that sinks at the end, short gaps and a little
    breath. Their own rng."""
    r = np.random.default_rng(91)
    vowels = [(730, 1090), (520, 920), (450, 800), (600, 1550), (300, 870), (660, 1700)]   # ah uh oh eh oo ae

    def resonate(x, f, bw):
        # two-pole resonator (band-pass) at f Hz
        rr = np.exp(-np.pi * bw / SR)
        c1, c2 = 2 * rr * np.cos(2 * np.pi * f / SR), -rr * rr
        y = np.zeros_like(x)
        y1 = y2 = 0.0
        for i in range(len(x)):
            y0 = x[i] + c1 * y1 + c2 * y2
            y[i] = y0
            y2, y1 = y1, y0
        return y * (1 - rr)

    def syllable(f0, dur, vowel, nasal):
        n = int(SR * dur)
        t = np.arange(n) / SR
        wob = 1 + 0.035 * np.sin(2 * np.pi * r.uniform(5, 8) * t) + 0.02 * r.uniform(-1, 1)
        contour = np.linspace(1.04, 0.9, n)   # each syllable sags a little
        ph = 2 * np.pi * np.cumsum(f0 * wob * contour) / SR
        src = saw(ph) * 0.6 + np.sign(np.sin(ph)) * 0.25 + r.uniform(-1, 1, n) * 0.08   # gravelly buzz
        f1, f2 = vowel
        v = resonate(src, f1, 90) * 1.0 + resonate(src, f2, 130) * 0.55
        if nasal:   # "hm"/"mm": a closed, muffled hum
            v = lowpass(src, 380) * 0.9
        a = min(0.025, dur * 0.25)
        return v * env(n, a, dur * 1.8, 0.03)

    for k in range(1, 7):
        count = [2, 3, 3, 4, 5, 6][k - 1]
        f0 = r.uniform(92, 128)
        parts = []
        for s in range(count):
            last = s == count - 1
            dur = r.uniform(0.09, 0.17) * (1.35 if last else 1.0)
            pitch = f0 * r.uniform(0.92, 1.12) * (0.82 if last else 1.0)   # sinks at the end
            parts.append(syllable(pitch, dur, vowels[r.integers(len(vowels))], r.random() < 0.25))
            parts.append(np.zeros(int(SR * r.uniform(0.02, 0.06))))
        x = np.concatenate(parts)
        x = x + lowpass(r.uniform(-1, 1, len(x)), 1800) * 0.02   # breath
        write(f"mumble_{k}", x, 0.75)


def powerup_sounds():
    """Power-up sounds (the user's request, with the power-up effects):
    powerup_pickup (a power-up goes into a slot: a quick bright pentatonic
    sparkle rising up with a glassy shimmer), powerup_activate (a slot is used:
    a rising whoosh swelling into a warm major chord with a shimmering top) and
    powerup_expire (the last power-up runs out: a soft falling chime with a
    fizzling, darkening tail). Their own rng, so no other sound's noise shifts."""
    r = np.random.default_rng(123)

    def nz(dur):
        return r.uniform(-1, 1, int(SR * dur))

    def bell(f, dur, decay, bright=0.35):
        t = t_axis(dur)
        x = np.sin(2 * np.pi * f * t) + bright * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 18)
        return x * env(len(t), 0.002, decay)

    def at(x, sec):
        return np.concatenate([np.zeros(int(SR * sec)), x])

    # pickup: four rising notes (A pentatonic) + a high glassy shimmer
    notes = [81, 84, 86, 88]   # A5 C6 D6 E6
    parts = [at(bell(note_hz(m), 0.32, 0.28) * (0.7 + 0.1 * i), 0.045 * i) for i, m in enumerate(notes)]
    shim = highpass(nz(0.35), 5000) * env(int(SR * 0.35), 0.03, 0.25) * 0.25
    write("powerup_pickup", mix(*parts, at(shim, 0.05)), 0.75)

    # activate: rising filtered whoosh into a major chord swell with a shimmer
    d = 0.9
    wn = int(SR * 0.45)
    whoosh = lowpass(nz(0.45), np.linspace(400, 4500, wn)) * np.linspace(0, 1, wn) ** 1.5 * 0.9
    rise = sweep(220, 660, 0.45, tri, 0.8) * np.linspace(0, 1, wn) ** 2 * 0.35
    cn = int(SR * (d - 0.35))
    t = t_axis(d - 0.35)
    chord = sum(saw(2 * np.pi * note_hz(m) * t * (1 + 0.003 * k)) for k, m in enumerate((57, 61, 64, 69)))
    chord = lowpass(chord, np.linspace(3500, 1200, cn)) * env(cn, 0.02, 0.6) * 0.35
    sparkle = mix(*[at(bell(note_hz(m), 0.3, 0.22, 0.5) * 0.4, 0.38 + 0.05 * i) for i, m in enumerate((88, 93, 96))])
    write("powerup_activate", mix(whoosh, rise, at(chord, 0.35), sparkle), 0.8)

    # expire: falling three-note chime + a fizzle that darkens away
    notes = [88, 84, 79]   # E6 C6 G5
    parts = [at(bell(note_hz(m), 0.4, 0.35) * (0.8 - 0.15 * i), 0.09 * i) for i, m in enumerate(notes)]
    fn_ = int(SR * 0.6)
    fizz = lowpass(highpass(nz(0.6), 800), np.linspace(6000, 600, fn_)) * lowpass(r.uniform(0, 1, fn_), 30) \
        * env(fn_, 0.01, 0.5) * 0.6
    down = sweep(700, 250, 0.5, np.sin, 1.3) * env(int(SR * 0.5), 0.01, 0.45) * 0.2
    write("powerup_expire", mix(*parts, at(fizz, 0.05), at(down, 0.1)), 0.7)


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["breaks"]:   # just the break effects (the rest is slow and unchanged)
        break_sounds()
        print("break sounds written to", OUT)
        raise SystemExit
    if sys.argv[1:] == ["mumble"]:   # just Ugo's mumbles
        mumble_sounds()
        print("mumble sounds written to", OUT)
        raise SystemExit
    if sys.argv[1:] == ["powerups"]:   # just the power-up sounds
        powerup_sounds()
        print("power-up sounds written to", OUT)
        raise SystemExit
    sfx()
    music()
    zone_tracks()
    death_jingle()
    slide_sound()
    break_sounds()
    mumble_sounds()
    powerup_sounds()
    print("sounds written to", OUT)
