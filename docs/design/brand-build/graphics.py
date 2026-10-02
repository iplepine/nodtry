"""Play feature graphics (ko/en) + brand system sheet, rendered with Pretendard."""
import base64
import os
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build  # noqa: E402,F401
from build import (G, HEART, CHECK, BG_RECTS, ICON_MARK, defs, svg, render_html,  # noqa: E402
                   mark_group, OUT, TMP)

FONTS = os.path.join(HERE, '..', '..', '..', 'assets', 'fonts')


def font_face():
    css = ''
    for w, f in [(400, 'Pretendard-Regular.otf'), (500, 'Pretendard-Medium.otf'), (700, 'Pretendard-Bold.otf')]:
        b64 = base64.b64encode(open(os.path.join(FONTS, f), 'rb').read()).decode()
        css += (f"@font-face{{font-family:'P';font-weight:{w};"
                f"src:url(data:font/otf;base64,{b64}) format('opentype');}}")
    return f'<style>{css}</style>'


HEAD = font_face()


def tile(px, shadow=True):
    s = svg(1024, 1024, '<clipPath id="sq"><rect width="1024" height="1024" rx="229" ry="229"/></clipPath>'
            '<g clip-path="url(#sq)">' + BG_RECTS + ICON_MARK + '</g>', defs())
    sh = 'filter:drop-shadow(0 10px 24px rgba(179,18,63,.35));' if shadow else ''
    return f'<div style="width:{px}px;height:{px}px;{sh}">{s.replace("<svg ", f"<svg style=\'width:{px}px;height:{px}px\' ", 1)}</div>'


def big_mark(px):
    s = svg(1024, 1024, mark_group(G, HEART, CHECK, target='bbox', size=900, extra=' filter="url(#lift)"'),
            defs(blur=26, dy=22))
    return s.replace('<svg ', f"<svg style='width:{px}px;height:{px}px' ", 1)


def feature(lang):
    if lang == 'ko':
        head = '둘이 보면,<br>진짜 하게 돼요'
        sub = '연인·부부 운동 약속 · 오운완 인증샷 · 짝꿍의 인정'
        name, alt = '둘운완', 'DuoDone'
        hsize = 68
    else:
        head = 'Workouts you<br>actually do, together'
        sub = 'Couple workout promises · photo proof · partner cheers'
        name, alt = 'DuoDone', '둘운완'
        hsize = 60
    bg = svg(1024, 500, '<rect width="1024" height="500" fill="url(#bg)"/>'
             '<rect width="1024" height="500" fill="url(#glow)"/>', defs())
    body = f'''
<div style="position:relative;width:1024px;height:500px;overflow:hidden;font-family:'P',sans-serif">
  <div style="position:absolute;inset:0">{bg}</div>
  <div style="position:absolute;right:-34px;top:40px;opacity:1">{big_mark(470)}</div>
  <div style="position:absolute;left:64px;top:62px;display:flex;align-items:center;gap:16px">
    {tile(64)}
    <div style="color:#fff;line-height:1">
      <div style="font-weight:700;font-size:34px;letter-spacing:-0.5px">{name}</div>
      <div style="font-weight:500;font-size:17px;opacity:.85;margin-top:6px">{alt}</div>
    </div>
  </div>
  <div style="position:absolute;left:64px;top:178px;color:#fff;font-weight:700;font-size:{hsize}px;
              line-height:1.16;letter-spacing:-1.5px;text-shadow:0 2px 18px rgba(150,10,50,.18)">{head}</div>
  <div style="position:absolute;left:66px;bottom:58px;color:#fff;font-weight:500;font-size:20px;opacity:.92">{sub}</div>
</div>'''
    out = os.path.join(OUT, f'featureGraphic_{lang}.png')
    im = render_html(body, os.path.join(TMP, f'fg_{lang}_raw.png'), 1024, 500, bg='#FF506A', head=HEAD)
    im.convert('RGB').save(out, optimize=True)


feature('ko')
feature('en')


# ---------------------------------------------------------------- system sheet
def img_tag(path, px, style=''):
    b64 = base64.b64encode(open(path, 'rb').read()).decode()
    return f'<img src="data:image/png;base64,{b64}" style="width:{px}px;height:{px}px;{style}">'


def adaptive(px, shape_radius):
    bgp = img_tag(os.path.join(OUT, 'icon_background.png'), int(px * 1.5), 'position:absolute;left:-25%;top:-25%')
    fgp = img_tag(os.path.join(OUT, 'icon_foreground.png'), int(px * 1.5), 'position:absolute;left:-25%;top:-25%')
    return (f'<div style="position:relative;width:{px}px;height:{px}px;overflow:hidden;border-radius:{shape_radius}">'
            f'{bgp}{fgp}</div>')


def themed(px, bgc, ink):
    b64 = base64.b64encode(open(os.path.join(OUT, 'icon_monochrome.png'), 'rb').read()).decode()
    return (f'<div style="position:relative;width:{px}px;height:{px}px;overflow:hidden;border-radius:50%;background:{bgc}">'
            f'<div style="position:absolute;left:-25%;top:-25%;width:{int(px*1.5)}px;height:{int(px*1.5)}px;background:{ink};'
            f'-webkit-mask:url(data:image/png;base64,{b64}) center/contain no-repeat"></div></div>')


def notif(px):
    b64 = base64.b64encode(open(os.path.join(OUT, 'ic_stat_xxxhdpi.png'), 'rb').read()).decode()
    return (f'<div style="width:{px}px;height:{px}px;background:#fff;'
            f'-webkit-mask:url(data:image/png;base64,{b64}) center/contain no-repeat"></div>')


a12 = img_tag(os.path.join(OUT, 'splash_android12.png'), 84)
logo = img_tag(os.path.join(OUT, 'splash_logo.png'), 44)
sw = [('primary', '#D92653', '#fff'), ('primaryPressed', '#B81C45', '#fff'), ('primarySoft', '#FFE8ED', '#2B1B21'),
      ('secondary', '#FFD84D', '#2B1B21'), ('accentWine', '#8A5A00', '#fff'), ('background', '#FFF8F6', '#2B1B21'),
      ('surface', '#FFFFFF', '#2B1B21'), ('textPrimary', '#2B1B21', '#fff'), ('textSecondary', '#6F5C63', '#fff'),
      ('iconBG', '#FF506A', '#fff')]
swh = ''.join(f'<div style="width:100px"><div style="height:64px;border-radius:12px;background:{c};border:1px solid #0000001a;'
              f'display:flex;align-items:flex-end;padding:6px 8px;box-sizing:border-box;color:{t};font-weight:700;font-size:13px">Aa</div>'
              f'<div style="font-size:12px;font-weight:700;margin-top:6px">{n}</div><div style="font-size:11px;color:#6F5C63">{c}</div></div>'
              for n, c, t in sw)
lab = 'font-size:12px;color:#6F5C63;font-weight:500;margin-top:10px;text-align:center'
sheet = f'''
<div style="width:1200px;height:900px;background:#FFF8F6;font-family:'P',sans-serif;color:#2B1B21;position:relative;padding:40px;box-sizing:border-box">
  <div style="display:flex;align-items:center;gap:18px">{tile(72)}
    <div><div style="font-size:40px;font-weight:700;letter-spacing:-1px;line-height:1"><span style="color:#D92653">둘운완</span> · DuoDone</div>
    <div style="font-size:15px;color:#6F5C63;margin-top:8px">Brand system v1 — 김홍도 Heart-Check, 신사임당 방식으로 시스템화 (themed · notification · splash)</div></div></div>
  <div style="display:flex;gap:28px;margin-top:36px;align-items:flex-end">
    <div><div style="display:flex;gap:22px;align-items:flex-end">{tile(180)}{tile(120)}{tile(60)}</div><div style="{lab}">iOS / App Store (180 · 120 · 60pt)</div></div>
  </div>
  <div style="display:flex;gap:26px;margin-top:30px;align-items:flex-start">
    <div><div style="display:flex;gap:18px">{adaptive(96,'50%')}{adaptive(96,'30%')}{adaptive(96,'14%')}</div><div style="{lab}">Android adaptive (circle · squircle · rounded)</div></div>
    <div><div style="display:flex;gap:18px">{themed(96,'#D0E8DA','#2C4D3E')}{themed(96,'#2A2D35','#FFD6E0')}</div><div style="{lab}">Android 13 themed (monochrome)</div></div>
    <div><div style="display:flex;gap:14px;align-items:center;background:#202124;border-radius:16px;padding:16px 20px">{notif(24)}{notif(36)}{notif(48)}
      <div style="width:44px;height:44px;border-radius:50%;background:#D92653;display:flex;align-items:center;justify-content:center">{notif(26)}</div></div>
      <div style="{lab}">Notification small icon (white, 24dp) + accent #D92653</div></div>
  </div>
  <div style="position:absolute;right:40px;top:132px;display:flex;gap:18px">
    <div><div style="width:112px;height:228px;border-radius:18px;background:#FFF8F6;border:2px solid #2B1B21;display:flex;align-items:center;justify-content:center;overflow:hidden">{logo}</div><div style="{lab}">iOS · Android ≤11</div></div>
    <div><div style="width:112px;height:228px;border-radius:18px;background:#FFF8F6;border:2px solid #2B1B21;display:flex;align-items:center;justify-content:center;overflow:hidden">{a12}</div><div style="{lab}">Android 12+</div></div>
  </div>
  <div style="position:absolute;left:40px;bottom:40px;right:40px">
    <div style="font-size:14px;font-weight:700;margin-bottom:12px">In-app palette (light) — lib/theme/app_colors.dart</div>
    <div style="display:flex;gap:12px">{swh}</div>
    <div style="font-size:12px;color:#6F5C63;margin-top:14px">white on primary 4.82:1 AA · white on pressed 6.38:1 AA · primary on background 4.60:1 AA · text on yellow 11.85:1 AAA · yellow is a fill colour only (text-safe yellow family = accentWine 5.93:1)</div>
  </div>
</div>'''
im = render_html(sheet, os.path.join(TMP, 'sheet_raw.png'), 1200, 900, bg='#FFF8F6', head=HEAD)
im.convert('RGB').save(os.path.join(OUT, 'brand_system.png'), optimize=True)
print('graphics done')
