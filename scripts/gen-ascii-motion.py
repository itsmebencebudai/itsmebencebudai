#!/usr/bin/env python3
"""Render animated WebP assets: glyph-grid hero (light sweep) + typing terminal.
Original implementation: text -> coverage mask -> glyph per cell -> per-frame sweep."""
import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
MONOR = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
THEMES = {
 "dark":  dict(bg=(10,12,18), a=(125,211,252), b=(167,139,250), c=(240,171,252), hi=(255,255,255), dim=(42,51,80), txt=(127,138,168), bar=(20,24,36), cmd=(125,211,252), out=(195,202,223)),
 "light": dict(bg=(247,248,252), a=(37,99,235), b=(124,58,237), c=(219,39,119), hi=(20,10,60), dim=(201,207,226), txt=(91,100,133), bar=(232,235,245), cmd=(37,99,235), out=(38,48,79)),
}
def lerp(p, q, t): return tuple(int(p[i] + (q[i]-p[i])*t) for i in range(3))
def grad(T, x):
    return lerp(T["a"], T["b"], x/0.55) if x < .55 else lerp(T["b"], T["c"], (x-.55)/.45)

# ---------- hero ----------
TEXT, COLS, CW, CH, ROWS, S = "BENCE BUDAI", 118, 10, 17, 15, 2
W, H = COLS*CW, ROWS*CH + 70
RAMP = "·:+xX#@"
def coverage():
    img = Image.new("L", (COLS*8, ROWS*8), 0); d = ImageDraw.Draw(img); size = 400
    while True:
        f = ImageFont.truetype(SANS, size); x0,y0,x1,y1 = d.textbbox((0,0), TEXT, font=f)
        if x1-x0 <= img.width*.94 and y1-y0 <= img.height*.86: break
        size -= 4
    d.text(((img.width-(x1-x0))/2-x0, (img.height-(y1-y0))/2-y0), TEXT, fill=255, font=f)
    return img.filter(ImageFilter.GaussianBlur(1.2)).resize((COLS, ROWS), Image.LANCZOS)

def hero(name, T, frames=72, ms=45):
    m = coverage().load(); rnd = random.Random(7)
    f = ImageFont.truetype(MONO, 14*S); fs = ImageFont.truetype(MONOR, 13*S)
    cells, dust = [], []
    for r in range(ROWS):
        for c in range(COLS):
            v = m[c, r]/255; x, y = (c*CW+CW/2)*S, (14+r*CH)*S
            if v > .16: cells.append((c, x, y, v))
            elif rnd.random() < .07: dust.append((x, y, rnd.choice("·:.+"), rnd.random()*6.28))
    tag = "SOFTWARE DEVELOPER  ·  BACKEND  ·  AUTOMATION  ·  INFRASTRUCTURE"
    out = []
    for k in range(frames):
        t = k/frames
        im = Image.new("RGB", (W*S, H*S), T["bg"]); d = ImageDraw.Draw(im)
        band = -0.25 + 1.5*t                      # sweep position (0..1 across)
        for x, y, g, ph in dust:
            a = .15 + .35*(math.sin(ph + t*6.28)*.5+.5)
            d.text((x, y), g, font=f, fill=lerp(T["bg"], T["dim"], a+.3), anchor="mm")
        for c, x, y, v in cells:
            u = c/COLS; w = math.exp(-((u-band)/.09)**2)       # light band
            idx = min(len(RAMP)-1, int((v + .18*w)*len(RAMP)))
            base = lerp(T["bg"], grad(T, u), .78 + .08*math.sin(t*6.28 + u*6))
            d.text((x, y), RAMP[idx], font=f, fill=lerp(base, T["hi"], .85*w) , anchor="mm")
        tw = d.textlength(tag, font=fs) + len(tag)*2.2*S
        xx = (W*S - tw)/2
        for ch in tag:
            d.text((xx, (H-24)*S), ch, font=fs, fill=T["txt"], anchor="lm"); xx += d.textlength(ch, font=fs) + 2.2*S
        out.append(im.resize((W, H), Image.LANCZOS))
    out[0].save(f"assets/ascii-hero-{name}.webp", save_all=True, append_images=out[1:], duration=ms, loop=0, quality=88, method=6)

# ---------- terminal ----------
LINES = [("$ whoami", "Budai Bence - software developer, Budapest"),
         ("$ stack --list", "C# · .NET · ASP.NET Core · SQL Server · PowerShell"),
         ("$ infra --status", "Windows Server · IIS · Docker · Tailscale · homelab"),
         ("$ exploring", "local AI · MCP & agent tooling · developer experience"),
         ("$ build --useful --repeatable", None)]
def terminal(name, T, ms=50):
    TW, LH = 960, 30; TH = 64 + len(LINES)*2*LH - 10; f = ImageFont.truetype(MONOR, 16*S)
    ev = []                                      # (frame_index, line, chars_visible, kind)
    n = 0
    for cmd, out in LINES:
        for i in range(len(cmd)+1): ev.append((len(ev), cmd, i, "c"))
        ev += [(len(ev), cmd, len(cmd), "c")]*4
        if out:
            for i in range(0, len(out)+1, 3): ev.append((len(ev), out, min(i, len(out)), "o"))
            ev += [(len(ev), out, len(out), "o")]*6
    ev += [None]*50
    def draw(upto):
        im = Image.new("RGB", (TW*S, TH*S), T["bg"]); d = ImageDraw.Draw(im)
        d.rounded_rectangle((0,0,TW*S,TH*S), 12*S, fill=T["bg"])
        d.rectangle((0,0,TW*S,40*S), fill=T["bar"])
        for i, col in enumerate([(255,95,87),(254,188,46),(40,200,64)]): d.ellipse(((18+22*i)*S,15*S,(30+22*i)*S,27*S), fill=col)
        d.text((TW/2*S, 21*S), "bence@github — zsh", font=ImageFont.truetype(MONOR, 13*S), fill=T["txt"], anchor="mm")
        return im, d
    frames, shown, y = [], [], 80
    state = []  # finished lines
    cur = None
    seq = []
    li = 0
    for cmd, out in LINES:
        seq.append((cmd, "c"))
        if out: seq.append((out, "o"))
    # build frames from timeline
    timeline = []
    done = []
    for text, kind in seq:
        step = 1 if kind == "c" else 3
        for i in range(0, len(text)+1, step): timeline.append((list(done), text, i, kind))
        timeline.append((list(done), text, len(text), kind)); timeline += [(list(done), text, len(text), kind)]*(4 if kind=="c" else 6)
        done.append((text, kind))
    timeline += [(list(done), "", 0, "c")]*60
    for k, (fin, text, n, kind) in enumerate(timeline):
        im, d = draw(0); yy = 80
        def line(tx, kd, upto):
            nonlocal yy
            d.text((28*S, yy*S), tx[:upto], font=f, fill=T["cmd"] if kd == "c" else T["out"], anchor="ls")
            yy += LH if kd == "c" else LH+4
        for tx, kd in fin: line(tx, kd, len(tx))
        if text: line(text, kind, n)
        if (k//8) % 2 == 0:
            cx = 28*S + d.textlength((text or "")[:n], font=f) if text else 28*S
            cy = (yy - (LH if kind=="c" else LH+4))*S if text else yy*S
            d.rectangle((cx+2*S, cy-14*S, cx+11*S, cy+3*S), fill=T["b"])
        frames.append(im.resize((TW, TH), Image.LANCZOS))
    frames[0].save(f"assets/ascii-terminal-{name}.webp", save_all=True, append_images=frames[1:], duration=ms, loop=0, quality=85, method=6)

for name, T in THEMES.items():
    hero(name, T); terminal(name, T)
