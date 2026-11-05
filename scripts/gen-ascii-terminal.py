#!/usr/bin/env python3
"""Animated typing terminal SVG (CSS-only: stepped clip reveal + blinking cursor)."""
LINES = [
 ("$ whoami", "Budai Bence - software developer, Budapest"),
 ("$ stack --list", "C# · .NET · ASP.NET Core · SQL Server · PowerShell"),
 ("$ infra --status", "Windows Server · IIS · Docker · Tailscale · homelab"),
 ("$ exploring", "local AI · MCP & agent tooling · developer experience"),
 ("$ build --useful --repeatable", None),
]
import html
def build(t):
    p = dict(dark=dict(bg="#0a0c12", bar="#141824", cmd="#7dd3fc", out="#c3cadf", dim="#5d6788", ok="#a78bfa"),
             light=dict(bg="#f7f8fc", bar="#e8ebf5", cmd="#2563eb", out="#26304f", dim="#8a93b2", ok="#7c3aed"))[t]
    W, H, LH = 960, 60 + len(LINES) * 2 * 26 + 24, 26
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="100%" role="img" aria-label="Animated terminal introducing Bence">',
         '<style>',
         'text{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,"DejaVu Sans Mono",monospace;font-size:16px}',
         '.c{animation:ty var(--d) steps(var(--n),end) var(--s) both}',
         '@keyframes ty{from{clip-path:inset(0 100% 0 0)}to{clip-path:inset(0 0 0 0)}}',
         '.k{animation:bl 1s steps(1) infinite}@keyframes bl{50%{opacity:0}}',
         '@media (prefers-reduced-motion:reduce){.c{animation:none}.k{animation:none}}',
         '</style>',
         f'<rect width="{W}" height="{H}" rx="12" fill="{p["bg"]}"/>',
         f'<path d="M0 12a12 12 0 0 1 12-12h{W-24}a12 12 0 0 1 12 12v30H0z" fill="{p["bar"]}"/>',
         '<circle cx="24" cy="21" r="6" fill="#ff5f57"/><circle cx="46" cy="21" r="6" fill="#febc2e"/><circle cx="68" cy="21" r="6" fill="#28c840"/>',
         f'<text x="{W/2}" y="26" text-anchor="middle" fill="{p["dim"]}" style="font-size:13px">bence@github — zsh</text>']
    y, t0 = 78, 0.4
    for cmd, out in LINES:
        n = len(cmd)
        o.append(f'<text class="c" x="28" y="{y}" fill="{p["cmd"]}" style="--n:{n};--d:{n*0.045:.2f}s;--s:{t0:.2f}s">{html.escape(cmd)}</text>')
        t0 += n * 0.045 + 0.25
        if out:
            y += LH
            n = len(out)
            o.append(f'<text class="c" x="28" y="{y}" fill="{p["out"]}" style="--n:{n};--d:{n*0.018:.2f}s;--s:{t0:.2f}s">{html.escape(out)}</text>')
            t0 += n * 0.018 + 0.3
        else:
            o.append(f'<text class="k" x="{28 + n*9.62:.0f}" y="{y}" fill="{p["ok"]}">█</text>')
        y += LH + 4
    o.append('</svg>')
    return "\n".join(o)
for t in ("dark", "light"):
    open(f"assets/ascii-terminal-{t}.svg", "w").write(build(t))
