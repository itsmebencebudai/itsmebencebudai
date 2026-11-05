#!/usr/bin/env python3
"""Generate animated glyph-grid hero SVGs (dark + light). Original implementation:
text -> coverage mask -> per-cell glyph from an ink ramp -> staggered CSS shimmer."""
import random, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

TEXT = sys.argv[1] if len(sys.argv) > 1 else "BENCE BUDAI"
COLS, CW, CH = 118, 10, 17            # grid columns, cell width/height (px)
ROWS = 15
W, H = COLS * CW, ROWS * CH + 70
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
RAMP = ["·", ":", "+", "x", "X", "#", "@"]

def mask():
    img = Image.new("L", (COLS * 8, ROWS * 8), 0)
    d = ImageDraw.Draw(img)
    size = 400
    while True:
        f = ImageFont.truetype(FONT, size)
        x0, y0, x1, y1 = d.textbbox((0, 0), TEXT, font=f)
        if x1 - x0 <= img.width * 0.94 and y1 - y0 <= img.height * 0.86:
            break
        size -= 4
    d.text(((img.width - (x1 - x0)) / 2 - x0, (img.height - (y1 - y0)) / 2 - y0), TEXT, fill=255, font=f)
    return img.filter(ImageFilter.GaussianBlur(1.2))

def build(theme):
    p = dict(
        dark=dict(bg="#0a0c12", g1="#7dd3fc", g2="#a78bfa", g3="#f0abfc", dim="#2a3350", txt="#7f8aa8", glow="#7dd3fc"),
        light=dict(bg="#f7f8fc", g1="#2563eb", g2="#7c3aed", g3="#db2777", dim="#c9cfe2", txt="#5b6485", glow="#7c3aed"),
    )[theme]
    m = mask().resize((COLS, ROWS), Image.LANCZOS)
    px = m.load()
    rnd = random.Random(7)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="100%" role="img" '
           f'aria-label="{TEXT} - animated ASCII glyph-grid banner">',
           f'<title>{TEXT}</title>',
           '<defs>',
           f'<linearGradient id="g" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="{p["g1"]}"/>'
           f'<stop offset=".55" stop-color="{p["g2"]}"/><stop offset="1" stop-color="{p["g3"]}"/></linearGradient>',
           f'<radialGradient id="v" cx=".5" cy=".5" r=".75"><stop offset="0" stop-color="{p["glow"]}" stop-opacity=".10"/>'
           f'<stop offset="1" stop-color="{p["glow"]}" stop-opacity="0"/></radialGradient>',
           '</defs>',
           '<style>',
           'text{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,"DejaVu Sans Mono",monospace;font-size:15px;text-anchor:middle}',
           '.s{fill:url(#g);opacity:.8;animation:sh 7s ease-in-out infinite}',
           '.d{opacity:.5;animation:tw 5s ease-in-out infinite}',
           '@keyframes sh{0%{opacity:.78}6%{opacity:1}16%{opacity:.84}100%{opacity:.78}}',
           '@keyframes tw{0%,100%{opacity:.18}50%{opacity:.7}}',
           '.cur{animation:bl 1.1s steps(1) infinite}@keyframes bl{50%{opacity:0}}',
           '@media (prefers-reduced-motion:reduce){.s,.d,.cur{animation:none}.s{opacity:.9}.d{opacity:.35}}',
           '</style>',
           f'<rect width="{W}" height="{H}" rx="14" fill="{p["bg"]}"/>',
           f'<rect width="{W}" height="{H}" rx="14" fill="url(#v)"/>']
    for r in range(ROWS):
        for c in range(COLS):
            v = px[c, r] / 255
            x, y = c * CW + CW / 2, 18 + r * CH + CH * 0.8
            if v > 0.16:
                g = RAMP[min(len(RAMP) - 1, int(v * len(RAMP)))]
                delay = round(c / COLS * 4.2 + r * 0.03, 2)
                out.append(f'<text class="s" x="{x:g}" y="{y:g}" style="animation-delay:{delay}s">{g}</text>')
            elif rnd.random() < 0.07:
                out.append(f'<text class="d" x="{x:g}" y="{y:g}" fill="{p["dim"]}" '
                           f'style="animation-delay:{round(rnd.random()*5,2)}s">{rnd.choice("·:.+")}</text>')
    ty = H - 22
    out.append(f'<text x="{W/2}" y="{ty}" fill="{p["txt"]}" style="font-size:14px;letter-spacing:.14em">'
               f'SOFTWARE DEVELOPER  ·  BACKEND  ·  AUTOMATION  ·  INFRASTRUCTURE<tspan class="cur" fill="{p["g1"]}"> █</tspan></text>')
    out.append('</svg>')
    return "\n".join(out)

for t in ("dark", "light"):
    open(f"assets/ascii-hero-{t}.svg", "w").write(build(t))
