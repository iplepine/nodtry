"""Builds the lightweight Pretendard subsets in assets/fonts/.

The full Pretendard 1.301 OTFs (~1.6 MB each) caused an Android cold-start
ANR (a0a1ac6), so the app ships subsets (~350 KB each) instead:

- ASCII, Latin-1, General Punctuation, arrows, circled numbers, CJK brackets
  and a short list of common UI symbols,
- Hangul Compatibility Jamo and the 2,350 KS X 1001 Hangul syllables,
- every character in lib/ and tool/ (.dart and .arb, so all ARB copy and
  Dart string literals, plus the store screenshot fixtures).

Left out on purpose, so they fall back to the system fonts per glyph:
code points with the Unicode Emoji property (a Pretendard text glyph would
win over the color emoji for "❤️", "☀️" ...), ZWJ / variation selectors /
other invisible format characters (emoji sequences resolve as one fallback
run), and anything outside the BMP.

Layout features kept: kern, mark, mkmk, ccmp, locl, tnum (tabular figures
are used in the UI), case. Hinting is dropped (CFF hints barely matter on
high-DPI phones) and the CFF is re-subroutinized with AFDKO tx.

Usage (needs fonttools, brotli and cffsubr, e.g. in a throwaway venv):

    python3 -m venv /path/to/venv
    /path/to/venv/bin/pip install fonttools brotli cffsubr
    # The full fonts live in git history (commit 438b7f7):
    for w in Regular Medium Bold; do
      git show 438b7f7:assets/fonts/Pretendard-$w.otf > /path/to/src/Pretendard-$w.otf
    done
    /path/to/venv/bin/python -I tool/fonts/subset_pretendard.py \\
        --src /path/to/src --repo . --out assets/fonts

Re-run it after adding copy with Hangul syllables outside KS X 1001 or new
symbols (test/theme/pretendard_font_assets_test.dart reports them).
"""
import argparse
import os
import sys

WEIGHTS = ('Regular', 'Medium', 'Bold')

# Unicode Emoji=Yes code points in the BMP (emoji-data.txt), minus ASCII
# keycap bases and the Latin-1 (C)/(R) signs.
EMOJI_BMP = """
203C 2049 2122 2139 2194-2199 21A9-21AA 231A-231B 2328 23CF 23E9-23F3
23F8-23FA 24C2 25AA-25AB 25B6 25C0 25FB-25FE 2600-2604 260E 2611
2614-2615 2618 261D 2620 2622-2623 2626 262A 262E-262F 2638-263A 2640
2642 2648-2653 265F-2660 2663 2665-2666 2668 267B 267E-267F 2692-2697
2699 269B-269C 26A0-26A1 26A7 26AA-26AB 26B0-26B1 26BD-26BE 26C4-26C5
26C8 26CE-26CF 26D1 26D3-26D4 26E9-26EA 26F0-26F5 26F7-26FA 26FD 2702
2705 2708-270D 270F 2712 2714 2716 271D 2721 2728 2733-2734 2744 2747
274C 274E 2753-2755 2757 2763-2764 2795-2797 27A1 27B0 27BF 2934-2935
2B05-2B07 2B1B-2B1C 2B50 2B55 3030 303D 3297 3299
"""

# Invisible / format characters: ZWSP..RLM, line/para separators, bidi
# controls, NNBSP, word joiner.., variation selectors, keycap, BOM.
FORMAT_RANGES = (
    (0x200B, 0x200F), (0x2028, 0x202F), (0x2060, 0x206F),
    (0xFE00, 0xFE0F), (0x20E3, 0x20E3), (0xFEFF, 0xFEFF),
)

COMMON_SYMBOLS = (
    '₩€℃№℉∙−±≤≥≠≈∼∞√·×÷'
    '●○◎◉■□▪▫▲△▼▽◀▶◆◇◈★☆♡♤♧♢✓✕✗✘※〜～'
)


def ks_x_1001_syllables():
    # Python's euc-kr codec also encodes the other 8,822 syllables as 8-byte
    # KS X 1001 Annex 3 jamo sequences; only the 2-byte ones are in the table.
    out = [c for c in range(0xAC00, 0xD7A4)
           if len(chr(c).encode('euc-kr')) == 2]
    assert len(out) == 2350, len(out)
    return out


def scan_repo_chars(repo):
    found = set()
    for top in ('lib', 'tool'):
        for dirpath, _, files in os.walk(os.path.join(repo, top)):
            for name in files:
                if not name.endswith(('.dart', '.arb')):
                    continue
                with open(os.path.join(dirpath, name), encoding='utf-8') as fh:
                    found.update(ord(ch) for ch in fh.read() if ord(ch) >= 0x80)
    return found


def build_codepoints(repo):
    cps = set()

    def add(a, b):
        cps.update(range(a, b + 1))

    add(0x20, 0x7E)        # ASCII (digits included)
    add(0xA0, 0xFF)        # Latin-1 Supplement
    add(0x2010, 0x2027)    # General Punctuation: dashes, quotes, bullets, …
    add(0x2030, 0x205E)    # General Punctuation: ‰, primes, ※ ...
    add(0x2190, 0x21FF)    # arrows
    add(0x2460, 0x2473)    # ①..⑳
    add(0x3001, 0x3003)    # 、。〃
    add(0x3008, 0x3011)    # 〈〉《》「」『』【】
    add(0x3131, 0x318E)    # Hangul Compatibility Jamo
    cps.update(ord(ch) for ch in COMMON_SYMBOLS)
    cps.update(ks_x_1001_syllables())
    cps.update(scan_repo_chars(repo))

    for tok in EMOJI_BMP.split():
        a, _, b = tok.partition('-')
        cps.difference_update(range(int(a, 16), int(b or a, 16) + 1))
    for a, b in FORMAT_RANGES:
        cps.difference_update(range(a, b + 1))
    return sorted(c for c in cps if c < 0x10000 and not 0xE000 <= c <= 0xF8FF)


def subset_one(src, dst, codepoints):
    import cffsubr
    from fontTools import subset
    from fontTools.ttLib import TTFont

    options = subset.Options()
    options.layout_features = ['kern', 'mark', 'mkmk', 'ccmp', 'locl', 'tnum',
                               'case']
    options.hinting = False
    options.name_IDs = ['*']
    options.name_legacy = True
    options.name_languages = ['*']
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.drop_tables += ['DSIG']

    font = TTFont(src)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)
    cffsubr.subroutinize(font, keep_glyph_names=False)
    font.save(dst)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('--src', required=True,
                        help='folder with the full Pretendard-*.otf files')
    parser.add_argument('--repo', default='.', help='repo root to scan')
    parser.add_argument('--out', default='assets/fonts')
    args = parser.parse_args()

    codepoints = build_codepoints(args.repo)
    print(f'{len(codepoints)} code points requested')
    for weight in WEIGHTS:
        name = f'Pretendard-{weight}.otf'
        dst = os.path.join(args.out, name)
        subset_one(os.path.join(args.src, name), dst, codepoints)
        print(f'{dst}: {os.path.getsize(dst):,} bytes')
    return 0


if __name__ == '__main__':
    sys.exit(main())
