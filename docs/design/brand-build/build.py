"""Build 둘운완 / DuoDone brand masters from 김홍도's Heart-Check geometry.

Usage: python3 docs/design/brand-build/build.py  (needs Google Chrome + Pillow)
Outputs go to docs/design/brand-build/out/ (scratch output, do not commit; copy what you need):
  icon_1024.png          opaque, full-bleed iOS/Play/web master (no rounded corners)
  icon_background.png    adaptive background: coral gradient + glow (opaque)
  icon_foreground.png    adaptive foreground: mark inside the 66% safe zone (transparent)
  icon_monochrome.png    Android 13 themed icon silhouette (black on transparent)
  splash_android12.png   1152 canvas, gradient disc + mark inside the centre 2/3 circle
  splash_logo.png        512 canvas, 384px rounded tile (96pt @4x) + soft shadow, transparent
  app_icon_512.png       in-app logo, 512 rounded tile, transparent corners, no shadow
  ic_stat_<dpi>.png      Android notification small icon, white on transparent, 24dp base
  play_icon_512.png      Play store icon, opaque full-bleed 512
  svg/*.svg              vector sources
"""
import base64
import math
import os
import subprocess
import sys

from PIL import Image

HERE_ = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE_)
from mark import geom, mark_group, placement, sample_points, _outline_pts  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'out')
TMP = os.path.join(HERE, 'tmp')
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, 'svg'), exist_ok=True)
os.makedirs(TMP, exist_ok=True)
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

G = geom(260, 230, 420, 0, tip=34)
BG1, BG2 = '#FF6B5E', '#FF3577'
HEART, CHECK = '#FFD84D', '#FFFFFF'


def render_html(body, out_png, w, h, bg='transparent', head=''):
    page = os.path.join(TMP, os.path.basename(out_png).replace('.png', '.html'))
    with open(page, 'w') as f:
        f.write('<!doctype html><html><head><meta charset="utf-8">' + head +
                f'<style>html,body{{margin:0;padding:0;background:{bg};overflow:hidden}}'
                'svg{display:block}</style></head><body>' + body + '</body></html>')
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=1', '--default-background-color=00000000',
                    '--allow-file-access-from-files',
                    f'--window-size={w},{h}', f'--screenshot={out_png}', 'file://' + page],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    im = Image.open(out_png)
    assert im.size == (w, h), (out_png, im.size)
    return im


def defs(prefix='', blur=22, dy=18):
    return (
        f'<linearGradient id="{prefix}bg" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{BG1}"/><stop offset="1" stop-color="{BG2}"/></linearGradient>'
        f'<radialGradient id="{prefix}glow" cx="0.2" cy="0.16" r="0.8">'
        '<stop offset="0" stop-color="#FFFFFF" stop-opacity="0.13"/>'
        '<stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>'
        f'<filter id="{prefix}lift" x="-20%" y="-20%" width="140%" height="150%" color-interpolation-filters="sRGB">'
        f'<feGaussianBlur in="SourceAlpha" stdDeviation="{blur}"/><feOffset dy="{dy}" result="b"/>'
        '<feFlood flood-color="#B3123F" flood-opacity="0.30"/><feComposite in2="b" operator="in"/>'
        '<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
    )


def svg(w, h, inner, d='', vb=None):
    vb = vb or f'0 0 {w} {h}'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}">'
            + (f'<defs>{d}</defs>' if d else '') + inner + '</svg>')


def save_rgb(im, path):
    im.convert('RGB').save(path, optimize=True)


def save_rgba(im, path):
    im.convert('RGBA').save(path, optimize=True)


# ---------------------------------------------------------------- 1024 masters
ICON_MARK = mark_group(G, HEART, CHECK, size=664, bias=(0, 6), extra=' filter="url(#lift)"')
# Android: mark enclosing circle r=270 (< 313 safe-zone radius) so circle masks keep breathing room
FG_SIZE = 540
FG_MARK = mark_group(G, HEART, CHECK, target='blend', size=FG_SIZE, extra=' filter="url(#lift)"')
FG_MARK_FLAT = mark_group(G, HEART, CHECK, target='blend', size=FG_SIZE)
MONO_MARK = mark_group(G, '#000000', None, target='blend', size=FG_SIZE)
BG_RECTS = '<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#glow)"/>'

icon_svg = svg(1024, 1024, '<title>둘운완 / DuoDone app icon - Heart-Check</title>' + BG_RECTS + ICON_MARK, defs())
bg_svg = svg(1024, 1024, '<title>둘운완 adaptive background</title>' + BG_RECTS, defs())
fg_svg = svg(1024, 1024, '<title>둘운완 adaptive foreground</title>' + FG_MARK, defs())
mono_svg = svg(1024, 1024, '<title>둘운완 monochrome</title>' + MONO_MARK)

for name, s in [('icon', icon_svg), ('icon_background', bg_svg), ('icon_foreground', fg_svg),
                ('icon_monochrome', mono_svg)]:
    with open(os.path.join(OUT, 'svg', name + '.svg'), 'w') as f:
        f.write(s + '\n')

save_rgb(render_html(icon_svg, os.path.join(TMP, 'icon_raw.png'), 1024, 1024, bg='#000'),
         os.path.join(OUT, 'icon_1024.png'))
save_rgb(render_html(bg_svg, os.path.join(TMP, 'bg_raw.png'), 1024, 1024, bg='#000'),
         os.path.join(OUT, 'icon_background.png'))
save_rgba(render_html(fg_svg, os.path.join(TMP, 'fg_raw.png'), 1024, 1024),
          os.path.join(OUT, 'icon_foreground.png'))
save_rgba(render_html(mono_svg, os.path.join(TMP, 'mono_raw.png'), 1024, 1024),
          os.path.join(OUT, 'icon_monochrome.png'))

# Play icon 512 (opaque, full-bleed; Play applies its own mask)
Image.open(os.path.join(OUT, 'icon_1024.png')).resize((512, 512), Image.LANCZOS).save(
    os.path.join(OUT, 'play_icon_512.png'), optimize=True)

# ------------------------------------------------- Android 12 splash (1152)
# Visible area = centre circle of 768px. Draw our own gradient disc slightly
# inside it (752) so the edge is anti-aliased by us, not the system mask.
D = 752
C = 1152 / 2
sc_disc = D / 1024.0  # treat the disc as a 1024 icon scaled to D
# mark: same proportion as the launcher foreground (enclosing r=306 within visible r=341)
MARK_IN_DISC = mark_group(G, HEART, CHECK, canvas=1152, target='blend', size=int(round(D * 0.76)),
                          extra=' filter="url(#lift)"')
a12_inner = (
    '<title>둘운완 Android 12 splash icon</title>'
    f'<circle cx="{C}" cy="{C}" r="{D / 2}" fill="url(#bg)"/>'
    f'<circle cx="{C}" cy="{C}" r="{D / 2}" fill="url(#glow)"/>'
    + MARK_IN_DISC
)
a12_svg = svg(1152, 1152, a12_inner, defs(blur=18, dy=14))
with open(os.path.join(OUT, 'svg', 'splash_android12.svg'), 'w') as f:
    f.write(a12_svg + '\n')
save_rgba(render_html(a12_svg, os.path.join(TMP, 'a12_raw.png'), 1152, 1152),
          os.path.join(OUT, 'splash_android12.png'))


# ------------------------------------------------ rounded tiles (logo/splash)
def tile_svg(canvas, tile, radius_ratio=0.2237, shadow=False, title='tile'):
    off = (canvas - tile) / 2
    s = tile / 1024.0
    r = 1024 * radius_ratio
    shadow_def = (
        '<filter id="drop" x="-30%" y="-30%" width="160%" height="170%" color-interpolation-filters="sRGB">'
        '<feGaussianBlur in="SourceAlpha" stdDeviation="40"/><feOffset dy="34" result="b"/>'
        '<feFlood flood-color="#FF3577" flood-opacity="0.28"/><feComposite in2="b" operator="in"/>'
        '<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
    ) if shadow else ''
    inner = (
        f'<title>{title}</title>'
        f'<clipPath id="sq"><rect width="1024" height="1024" rx="{r:.1f}" ry="{r:.1f}"/></clipPath>'
        f'<g transform="translate({off} {off}) scale({s:.5f})">'
        + (f'<g filter="url(#drop)">' if shadow else '<g>')
        + f'<g clip-path="url(#sq)">' + BG_RECTS + ICON_MARK + '</g></g></g>'
    )
    return svg(canvas, canvas, inner, defs() + shadow_def)


logo_svg = tile_svg(512, 384, shadow=True, title='둘운완 splash logo')
with open(os.path.join(OUT, 'svg', 'splash_logo.svg'), 'w') as f:
    f.write(logo_svg + '\n')
save_rgba(render_html(logo_svg, os.path.join(TMP, 'logo_raw.png'), 512, 512),
          os.path.join(OUT, 'splash_logo.png'))

app_svg = tile_svg(512, 512, title='둘운완 in-app logo')
save_rgba(render_html(app_svg, os.path.join(TMP, 'app_raw.png'), 512, 512),
          os.path.join(OUT, 'app_icon_512.png'))

# ------------------------------------------- notification small icon (24dp)
# Silhouette in white; fit the mark's bbox into the 20dp live area (2dp padding).
sc0, tx0, ty0 = placement(G, 1024, 'bbox', 1000, (0, 0))
pts = [(p[0] * sc0 + tx0, p[1] * sc0 + ty0) for p in sample_points(G)]
xs = [p[0] for p in pts]
ys = [p[1] for p in pts]
bw, bh = max(xs) - min(xs), max(ys) - min(ys)
side = max(bw, bh) * 24 / 20.0  # 2dp padding each side on a 24dp canvas
cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
vb = f'{cx - side / 2:.2f} {cy - side / 2:.2f} {side:.2f} {side:.2f}'
stat_mark = mark_group(G, '#FFFFFF', None, target='bbox', size=1000)
for dpi, px in [('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96)]:
    s = svg(px, px, stat_mark, vb=vb)
    im = render_html(s, os.path.join(TMP, f'stat_{dpi}_raw.png'), px, px)
    # force pure white RGB, keep only alpha (Android ignores colour anyway)
    a = im.convert('RGBA').split()[3]
    white = Image.new('RGBA', (px, px), (255, 255, 255, 0))
    white.putalpha(a)
    white.save(os.path.join(OUT, f'ic_stat_{dpi}.png'), optimize=True)
with open(os.path.join(OUT, 'svg', 'ic_stat_duodone.svg'), 'w') as f:
    f.write(svg(24, 24, stat_mark, vb=vb) + '\n')

print('done')
