#!/usr/bin/env python3
# Author: Alexander Ford <alex@pseudo-lang.com>
# Repository: https://github.com/alexander-ford-ventures/project-architect
# License: MIT
"""Render 5 logo concepts for Alexander Ford Ventures.

Each concept ships in two variants — light (black ink on white) and dark
(white ink on black). For each variant we emit an SVG (vector source-of-
truth) and a PNG preview. A final contact sheet composites all 10 PNGs
into one image so they can be compared at a glance.

Run:
    /tmp/pdfbuild-venv/bin/python .github/assets/logo-concepts/build_concepts.py
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent.parent
FONT_TTF = REPO_ROOT / "docs" / "explainer" / "fonts" / "GeistMono-ExtraBold.ttf"
FONT_REG_TTF = REPO_ROOT / "docs" / "explainer" / "fonts" / "GeistMono-Regular.ttf"
FONT_MED_TTF = REPO_ROOT / "docs" / "explainer" / "fonts" / "GeistMono-Medium.ttf"
GEIST_SANS_TTF = REPO_ROOT / "docs" / "explainer" / "fonts" / "Geist-Bold.ttf"

INK_LIGHT = (10, 10, 10)        # near-black for light variant
PAPER_LIGHT = (255, 255, 255)
INK_DARK = (255, 255, 255)      # white for dark variant
PAPER_DARK = (10, 10, 10)


@dataclass
class Variant:
    name: str        # e.g. "light" / "dark"
    ink: tuple
    paper: tuple


VARIANTS = [
    Variant("light", INK_LIGHT, PAPER_LIGHT),
    Variant("dark", INK_DARK, PAPER_DARK),
]


# ── SVG helpers ────────────────────────────────────────────────────────────


def svg_open(w, h, paper):
    paper_hex = "#%02X%02X%02X" % paper
    return (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="0 0 {w} {h}" width="{w}" height="{h}">\n'
        f'  <rect width="{w}" height="{h}" fill="{paper_hex}"/>\n'
    )


def svg_close():
    return "</svg>\n"


def hex_of(rgb):
    return "#%02X%02X%02X" % rgb


# ── Concept builders (return SVG string + Pillow Image preview) ────────────


def measure(text, font):
    """Return (w, h) bounding box for given text + font (PIL)."""
    img = Image.new("RGBA", (1, 1))
    draw = ImageDraw.Draw(img)
    bbox = draw.textbbox((0, 0), text, font=font)
    return (bbox[2] - bbox[0], bbox[3] - bbox[1]), bbox


def concept_1_afv_monogram(variant):
    """Square 1:1 monogram. Big AFL centered, Geist Mono ExtraBold."""
    size = 1024
    text = "AFL"
    # PNG render
    img = Image.new("RGB", (size, size), variant.paper)
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT_TTF), 380)
    (tw, th), bbox = measure(text, font)
    x = (size - tw) // 2 - bbox[0]
    y = (size - th) // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=variant.ink)

    # SVG render — text uses Geist Mono font; consumers must have it for parity
    svg = svg_open(size, size, variant.paper)
    svg += (
        f'  <text x="{size/2}" y="{size/2}" '
        f'font-family="Geist Mono, monospace" font-weight="800" '
        f'font-size="380" letter-spacing="-12" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{hex_of(variant.ink)}">{text}</text>\n'
    )
    svg += svg_close()
    return svg, img


def concept_2_aford_wordmark(variant):
    """Horizontal wordmark with leading period — '.aford'."""
    w, h = 1600, 480
    text = ".aford"
    img = Image.new("RGB", (w, h), variant.paper)
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT_TTF), 280)
    (tw, th), bbox = measure(text, font)
    x = (w - tw) // 2 - bbox[0]
    y = (h - th) // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=variant.ink)

    svg = svg_open(w, h, variant.paper)
    svg += (
        f'  <text x="{w/2}" y="{h/2}" '
        f'font-family="Geist Mono, monospace" font-weight="800" '
        f'font-size="280" letter-spacing="-6" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{hex_of(variant.ink)}">{text}</text>\n'
    )
    svg += svg_close()
    return svg, img


def concept_3_ford_editorial(variant):
    """Editorial venture-firm style: rule + FORD + small VENTURES tagline."""
    w, h = 1600, 720
    img = Image.new("RGB", (w, h), variant.paper)
    draw = ImageDraw.Draw(img)
    big = ImageFont.truetype(str(FONT_TTF), 260)
    tag = ImageFont.truetype(str(FONT_MED_TTF), 48)

    # Top rule
    pad_x = 220
    rule_y_top = 240
    draw.rectangle([pad_x, rule_y_top, w - pad_x, rule_y_top + 4], fill=variant.ink)

    # FORD wordmark
    text = "FORD"
    (tw, th), bbox = measure(text, big)
    fx = (w - tw) // 2 - bbox[0]
    fy = rule_y_top + 50 - bbox[1]
    draw.text((fx, fy), text, font=big, fill=variant.ink)

    # Bottom rule + tagline
    rule_y_bot = fy + th + bbox[1] + 60
    draw.rectangle([pad_x, rule_y_bot, w - pad_x, rule_y_bot + 2], fill=variant.ink)
    tagline = "ALEXANDER  ·  VENTURES  ·  EST 2026"
    (tagw, tagh), tbbox = measure(tagline, tag)
    tx = (w - tagw) // 2 - tbbox[0]
    ty = rule_y_bot + 30 - tbbox[1]
    draw.text((tx, ty), tagline, font=tag, fill=variant.ink)

    svg = svg_open(w, h, variant.paper)
    ink = hex_of(variant.ink)
    svg += f'  <rect x="{pad_x}" y="{rule_y_top}" width="{w - 2*pad_x}" height="4" fill="{ink}"/>\n'
    svg += (
        f'  <text x="{w/2}" y="{rule_y_top + 50 + th/2}" '
        f'font-family="Geist Mono, monospace" font-weight="800" '
        f'font-size="260" letter-spacing="-4" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{ink}">FORD</text>\n'
    )
    svg += f'  <rect x="{pad_x}" y="{rule_y_bot}" width="{w - 2*pad_x}" height="2" fill="{ink}"/>\n'
    svg += (
        f'  <text x="{w/2}" y="{rule_y_bot + 30 + tagh/2}" '
        f'font-family="Geist Mono, monospace" font-weight="500" '
        f'font-size="48" letter-spacing="6" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{ink}">ALEXANDER  ·  VENTURES  ·  EST 2026</text>\n'
    )
    svg += svg_close()
    return svg, img


def concept_4_af_interlock(variant):
    """Refined interlock — v3.  A's apex and crossbar CONTINUE through the shared
    central stem and become the F's top and middle arms. v3 changes vs v2:
      · steeper A left-leg slant for a more dynamic, classical A geometry
      · F middle arm noticeably shorter than top arm — classical F proportion
      · crossbar at 48% from top (was 52%) — optical-centre for capital A
      · slight stroke reduction to 104 (was 112) — more elegance, less brutalism
      · shared stem nudged right for tighter balance between A-mass and F-mass
    """
    size = 1024
    img = Image.new("RGB", (size, size), variant.paper)
    draw = ImageDraw.Draw(img)
    ink = variant.ink

    # Uniform stroke weight (thinner than v2 by ~7% — reads as more architectural)
    stroke = 104
    top_y = 210
    bot_y = size - 210
    h = bot_y - top_y

    # Shared central vertical stem position (LEFT edge of the stem).  Nudged right
    # from 470 → 500 so the F's two arms have more horizontal runway, which
    # improves the read of the F as an independent letter while still sharing
    # the stem with the A.
    stem_x = 500

    # A's left leg slants outward toward the bottom-left.  Steeper than v2:
    # a_bot_left 130 → 80 makes the slant ~28° instead of ~23°, giving the A
    # more dynamic character.
    a_top_left = stem_x - 88               # top of the slanted leg, just inside apex
    a_bot_left = 80                        # bottom of the slanted leg, far left

    # F's right edges — classical proportion: middle arm clearly shorter
    f_top_right = size - 110
    f_mid_right = f_top_right - 170        # was -90; now noticeably shorter than top

    # Crossbar at 48% — optical centre for a capital A (the visual centre sits
    # slightly above the mathematical centre because the lower half is wider).
    cross_y = int(top_y + h * 0.48)

    # ── 1. Continuous TOP BAR (A's apex + F's top arm)
    draw.rectangle([a_top_left, top_y, f_top_right, top_y + stroke], fill=ink)

    # ── 2. Shared central vertical stem (= A's right leg + F's stem)
    draw.rectangle([stem_x, top_y, stem_x + stroke, bot_y], fill=ink)

    # ── 3. A's slanted LEFT leg (polygon).  Its TOP edge meets the bottom of the
    # top bar so the two read as a single corner, not two abutting elements.
    draw.polygon(
        [
            (a_top_left, top_y + stroke),
            (a_top_left + stroke, top_y + stroke),
            (a_bot_left + stroke, bot_y),
            (a_bot_left, bot_y),
        ],
        fill=ink,
    )

    # ── 4. Continuous MIDDLE BAR (A's crossbar + F's middle arm).  Starts at the
    # inner edge of the slanted left leg at cross_y, runs straight across the
    # shared stem, terminates at the F's middle-arm right edge.
    leg_top_inner = a_top_left + stroke
    leg_bot_inner = a_bot_left + stroke
    leg_top_y_inner = top_y + stroke       # leg starts under the top bar
    t = (cross_y - leg_top_y_inner) / (bot_y - leg_top_y_inner)
    left_at_cross_inner = int(leg_top_inner + (leg_bot_inner - leg_top_inner) * t)
    draw.rectangle(
        [left_at_cross_inner, cross_y, f_mid_right, cross_y + stroke], fill=ink
    )

    # SVG mirror
    ink_hex = hex_of(ink)
    svg = svg_open(size, size, variant.paper)
    svg += (
        f'  <rect x="{a_top_left}" y="{top_y}" '
        f'width="{f_top_right - a_top_left}" height="{stroke}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <rect x="{stem_x}" y="{top_y}" width="{stroke}" '
        f'height="{bot_y - top_y}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <polygon points="{a_top_left},{top_y + stroke} '
        f'{a_top_left + stroke},{top_y + stroke} '
        f'{a_bot_left + stroke},{bot_y} {a_bot_left},{bot_y}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <rect x="{left_at_cross_inner}" y="{cross_y}" '
        f'width="{f_mid_right - left_at_cross_inner}" height="{stroke}" fill="{ink_hex}"/>\n'
    )
    svg += svg_close()
    return svg, img


def concept_5_f_block(variant):
    """Single letter 'F' centered in a solid black/white square."""
    size = 1024
    img = Image.new("RGB", (size, size), variant.ink)  # frame IS the ink
    draw = ImageDraw.Draw(img)
    # Inner letter is the paper color
    font = ImageFont.truetype(str(FONT_TTF), 760)
    text = "F"
    (tw, th), bbox = measure(text, font)
    x = (size - tw) // 2 - bbox[0]
    y = (size - th) // 2 - bbox[1] - 20
    draw.text((x, y), text, font=font, fill=variant.paper)

    svg = svg_open(size, size, variant.ink)
    # Override the background fill — frame IS the ink
    svg = svg.replace(hex_of(variant.paper), hex_of(variant.ink), 1)
    svg += (
        f'  <text x="{size/2}" y="{size/2}" '
        f'font-family="Geist Mono, monospace" font-weight="800" '
        f'font-size="760" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{hex_of(variant.paper)}">F</text>\n'
    )
    svg += svg_close()
    return svg, img


# ── Driver ────────────────────────────────────────────────────────────────


def concept_6_af_stack(variant):
    """Big 'AF' centered, small 'VENTURES' beneath, separated by a hairline rule.

    Square mark — works as avatar, app icon, social-preview chip, or letterhead.
    """
    size = 1024
    img = Image.new("RGB", (size, size), variant.paper)
    draw = ImageDraw.Draw(img)

    # Big AF
    af_font = ImageFont.truetype(str(FONT_TTF), 520)
    af_text = "AF"
    (afw, afh), afbbox = measure(af_text, af_font)
    af_x = (size - afw) // 2 - afbbox[0]
    af_y = int(size * 0.34) - afh // 2 - afbbox[1]
    draw.text((af_x, af_y), af_text, font=af_font, fill=variant.ink)

    # Hairline rule between AF and VENTURES
    rule_y = int(size * 0.66)
    rule_pad = int(size * 0.28)
    draw.rectangle(
        [rule_pad, rule_y, size - rule_pad, rule_y + 3], fill=variant.ink
    )

    # Small LABS, letter-spaced for editorial feel
    v_font = ImageFont.truetype(str(FONT_MED_TTF), 88)
    v_text = "L A B S"
    (vw, vh), vbbox = measure(v_text, v_font)
    v_x = (size - vw) // 2 - vbbox[0]
    v_y = rule_y + 52 - vbbox[1]
    draw.text((v_x, v_y), v_text, font=v_font, fill=variant.ink)

    # SVG version
    ink = hex_of(variant.ink)
    svg = svg_open(size, size, variant.paper)
    svg += (
        f'  <text x="{size/2}" y="{int(size*0.34)}" '
        f'font-family="Geist Mono, monospace" font-weight="800" '
        f'font-size="520" letter-spacing="-18" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{ink}">AF</text>\n'
    )
    svg += (
        f'  <rect x="{rule_pad}" y="{rule_y}" '
        f'width="{size - 2*rule_pad}" height="3" fill="{ink}"/>\n'
    )
    svg += (
        f'  <text x="{size/2}" y="{rule_y + 52 + vh/2}" '
        f'font-family="Geist Mono, monospace" font-weight="500" '
        f'font-size="88" letter-spacing="22" '
        f'text-anchor="middle" dominant-baseline="central" '
        f'fill="{ink}">LABS</text>\n'
    )
    svg += svg_close()
    return svg, img


def concept_7_af_built_from_a(variant):
    """The F is BUILT FROM the A's existing lines, not a separate letter.

    A has a vertical right leg (which doubles as the F's stem). The A's apex bar
    EXTENDS rightward and becomes the F's top arm — one continuous horizontal.
    The A's crossbar EXTENDS rightward and becomes the F's middle arm — one
    continuous horizontal. F has zero independent geometry.
    """
    size = 1024
    img = Image.new("RGB", (size, size), variant.paper)
    draw = ImageDraw.Draw(img)
    ink = variant.ink

    stem_w = 110
    top_y = 230
    bot_y = size - 230
    h = bot_y - top_y

    a_left_top_x = 220
    a_left_bot_x = 90              # left leg slants outward at the bottom
    a_right_x = 540                # vertical right stem position (LEFT edge of stem)
    f_arm_end_x = size - 130
    f_arm_mid_end_x = f_arm_end_x - 90

    # A's left leg (slanted polygon)
    draw.polygon(
        [
            (a_left_top_x, top_y),
            (a_left_top_x + stem_w, top_y),
            (a_left_bot_x + stem_w, bot_y),
            (a_left_bot_x, bot_y),
        ],
        fill=ink,
    )

    # A's right leg + F's stem (vertical rectangle, shared)
    draw.rectangle([a_right_x, top_y, a_right_x + stem_w, bot_y], fill=ink)

    # A's apex bar + F's top arm = ONE continuous horizontal
    draw.rectangle(
        [a_left_top_x, top_y, f_arm_end_x, top_y + stem_w], fill=ink
    )

    # A's crossbar + F's middle arm = ONE continuous horizontal at ~52% height
    cross_y = int(top_y + h * 0.52)
    cross_bar_h = int(stem_w * 0.85)
    # Snap the crossbar's LEFT start to where the slanted left leg meets cross_y
    t = (cross_y - top_y) / (bot_y - top_y)
    left_at_cross_inner = (a_left_top_x + stem_w) + ((a_left_bot_x + stem_w) - (a_left_top_x + stem_w)) * t
    draw.rectangle(
        [left_at_cross_inner, cross_y, f_arm_mid_end_x, cross_y + cross_bar_h],
        fill=ink,
    )

    # SVG mirror
    ink_hex = hex_of(ink)
    svg = svg_open(size, size, variant.paper)
    svg += (
        f'  <polygon points="{a_left_top_x},{top_y} {a_left_top_x + stem_w},{top_y} '
        f'{a_left_bot_x + stem_w},{bot_y} {a_left_bot_x},{bot_y}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <rect x="{a_right_x}" y="{top_y}" width="{stem_w}" '
        f'height="{bot_y - top_y}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <rect x="{a_left_top_x}" y="{top_y}" '
        f'width="{f_arm_end_x - a_left_top_x}" height="{stem_w}" fill="{ink_hex}"/>\n'
    )
    svg += (
        f'  <rect x="{left_at_cross_inner}" y="{cross_y}" '
        f'width="{f_arm_mid_end_x - left_at_cross_inner}" height="{cross_bar_h}" '
        f'fill="{ink_hex}"/>\n'
    )
    svg += svg_close()
    return svg, img


CONCEPTS = [
    ("01-afv-monogram", concept_1_afv_monogram),
    ("02-aford-wordmark", concept_2_aford_wordmark),
    ("03-ford-editorial", concept_3_ford_editorial),
    ("04-af-interlock", concept_4_af_interlock),
    ("05-f-block", concept_5_f_block),
    ("06-af-stack", concept_6_af_stack),
    ("07-af-built-from-a", concept_7_af_built_from_a),
]


def render_all():
    rendered = []  # [(label, variant, svg_path, png_path, image)]
    for slug, fn in CONCEPTS:
        for variant in VARIANTS:
            svg, img = fn(variant)
            svg_path = HERE / f"concept-{slug}-{variant.name}.svg"
            png_path = HERE / f"concept-{slug}-{variant.name}.png"
            svg_path.write_text(svg, encoding="utf-8")
            img.save(png_path, optimize=True)
            rendered.append((slug, variant, svg_path, png_path, img))
    return rendered


def make_contact_sheet(rendered, outpath):
    """5 rows × 2 cols (light | dark). Each cell sized to fit any aspect ratio."""
    cell_w, cell_h = 820, 460
    gutter = 20
    margin = 60
    cols = 2
    rows = len(CONCEPTS)
    total_w = margin * 2 + cell_w * cols + gutter * (cols - 1)
    label_h = 64
    total_h = margin * 2 + (cell_h + label_h + gutter) * rows

    sheet = Image.new("RGB", (total_w, total_h), (245, 245, 247))
    draw = ImageDraw.Draw(sheet)

    title_font = ImageFont.truetype(str(FONT_TTF), 56)
    sub_font = ImageFont.truetype(str(FONT_MED_TTF), 26)
    label_font = ImageFont.truetype(str(FONT_MED_TTF), 22)

    # Header
    title = "ALEX FORD LABS — LOGO CONCEPTS"
    (tw, th), tbbox = measure(title, title_font)
    draw.text(
        ((total_w - tw) // 2 - tbbox[0], 40),
        title,
        font=title_font,
        fill=(10, 10, 10),
    )
    sub = "5 directions · light + dark · Geist Mono ExtraBold"
    (sw, sh), sbbox = measure(sub, sub_font)
    draw.text(
        ((total_w - sw) // 2 - sbbox[0], 110),
        sub,
        font=sub_font,
        fill=(85, 94, 120),
    )

    grid_top = 180

    # Index by (concept_slug, variant_name)
    cells = {(r[0], r[1].name): r for r in rendered}

    concept_titles = {
        "01-afv-monogram": ("01 · AFL monogram",
                             "Three-letter mark, square chip — favicon-grade"),
        "02-aford-wordmark": ("02 · .aford wordmark",
                               "Leading-period homage to .pseudo brand language"),
        "03-ford-editorial": ("03 · Editorial FORD",
                               "Venture-firm gravitas — rule + wordmark + tagline"),
        "04-af-interlock":   ("04 · AF interlock (v3)",
                               "Steeper A · classical F · 48% crossbar · 104px stroke"),
        "05-f-block":        ("05 · F-block mark",
                               "Single-letter chip — favicon / app-icon size"),
        "06-af-stack":       ("06 · AF / LABS stack",
                               "Big AF, hairline rule, small letter-spaced LABS"),
        "07-af-built-from-a": ("07 · AF built from A",
                               "F has zero geometry — A's apex + crossbar EXTEND right"),
    }

    for row_idx, (slug, _) in enumerate(CONCEPTS):
        row_y = grid_top + row_idx * (cell_h + label_h + gutter)
        # Concept label above each row, centered across both cells
        ctitle, csub = concept_titles[slug]
        (lw, lh), lbbox = measure(ctitle, sub_font)
        draw.text(
            (margin - lbbox[0], row_y),
            ctitle,
            font=sub_font,
            fill=(10, 10, 10),
        )
        # Right-side small description
        (dw, dh), dbbox = measure(csub, label_font)
        draw.text(
            (total_w - margin - dw - dbbox[0], row_y + 6),
            csub,
            font=label_font,
            fill=(85, 94, 120),
        )
        cells_top = row_y + label_h - 16

        for col_idx, variant in enumerate(VARIANTS):
            cell_x = margin + col_idx * (cell_w + gutter)
            # Cell background = variant paper
            paper = variant.paper
            draw.rectangle(
                [cell_x, cells_top, cell_x + cell_w, cells_top + cell_h],
                fill=paper,
                outline=(220, 220, 224),
                width=1,
            )
            # Fit the rendered image into the cell with padding
            _, _, _, _, img = cells[(slug, variant.name)]
            pad = 24
            avail_w, avail_h = cell_w - pad * 2, cell_h - pad * 2
            iw, ih = img.size
            scale = min(avail_w / iw, avail_h / ih)
            new_w, new_h = int(iw * scale), int(ih * scale)
            resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            px = cell_x + (cell_w - new_w) // 2
            py = cells_top + (cell_h - new_h) // 2
            sheet.paste(resized, (px, py))

    # Footer
    foot = "Pick a direction and we'll refine it · alex@pseudo-lang.com"
    (fw, fh), fbbox = measure(foot, label_font)
    draw.text(
        ((total_w - fw) // 2 - fbbox[0], total_h - margin + 10),
        foot,
        font=label_font,
        fill=(85, 94, 120),
    )

    sheet.save(outpath, optimize=True)
    return outpath


def make_shortlist_sheet(rendered, outpath):
    """Focused 3-concept shortlist sheet — AFL, AF interlock v3, AF / LABS stack."""
    shortlist_slugs = ["01-afv-monogram", "04-af-interlock", "06-af-stack"]
    shortlist_titles = {
        "01-afv-monogram": ("01 · AFL monogram",
                             "Three-letter mark — favicon / avatar / sticker"),
        "04-af-interlock": ("04 · AF interlock (v3)",
                             "Primary mark — distinctive shape, scales down to favicon"),
        "06-af-stack":     ("06 · AF / LABS stack",
                             "Full lockup — social-preview, GitHub avatar, slide titles"),
    }
    cells = {(r[0], r[1].name): r for r in rendered}

    cell_w, cell_h = 820, 520
    gutter = 24
    margin = 70
    cols = 2
    rows = len(shortlist_slugs)
    label_h = 76
    total_w = margin * 2 + cell_w * cols + gutter * (cols - 1)
    total_h = margin * 2 + (cell_h + label_h + gutter) * rows + 40

    sheet = Image.new("RGB", (total_w, total_h), (245, 245, 247))
    draw = ImageDraw.Draw(sheet)

    title_font = ImageFont.truetype(str(FONT_TTF), 64)
    sub_font = ImageFont.truetype(str(FONT_MED_TTF), 28)
    desc_font = ImageFont.truetype(str(FONT_MED_TTF), 22)

    # Header
    title = "ALEX FORD LABS — SHORTLIST"
    (tw, _), tbbox = measure(title, title_font)
    draw.text(
        ((total_w - tw) // 2 - tbbox[0], 46),
        title,
        font=title_font,
        fill=(10, 10, 10),
    )
    sub = "3 picks · light + dark · Geist Mono ExtraBold · alexfordlabs.com"
    (sw, _), sbbox = measure(sub, sub_font)
    draw.text(
        ((total_w - sw) // 2 - sbbox[0], 122),
        sub,
        font=sub_font,
        fill=(85, 94, 120),
    )

    grid_top = 220

    for row_idx, slug in enumerate(shortlist_slugs):
        row_y = grid_top + row_idx * (cell_h + label_h + gutter)
        ctitle, csub = shortlist_titles[slug]
        (_, _), lbbox = measure(ctitle, sub_font)
        draw.text(
            (margin - lbbox[0], row_y),
            ctitle,
            font=sub_font,
            fill=(10, 10, 10),
        )
        (dw, _), dbbox = measure(csub, desc_font)
        draw.text(
            (total_w - margin - dw - dbbox[0], row_y + 6),
            csub,
            font=desc_font,
            fill=(85, 94, 120),
        )
        cells_top = row_y + label_h - 20

        for col_idx, variant in enumerate(VARIANTS):
            cell_x = margin + col_idx * (cell_w + gutter)
            draw.rectangle(
                [cell_x, cells_top, cell_x + cell_w, cells_top + cell_h],
                fill=variant.paper,
                outline=(220, 220, 224),
                width=1,
            )
            _, _, _, _, img = cells[(slug, variant.name)]
            pad = 32
            avail_w, avail_h = cell_w - pad * 2, cell_h - pad * 2
            iw, ih = img.size
            scale = min(avail_w / iw, avail_h / ih)
            new_w, new_h = int(iw * scale), int(ih * scale)
            resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            px = cell_x + (cell_w - new_w) // 2
            py = cells_top + (cell_h - new_h) // 2
            sheet.paste(resized, (px, py))

    sheet.save(outpath, optimize=True)
    return outpath


def main():
    if not FONT_TTF.exists():
        raise SystemExit(f"Missing font: {FONT_TTF}")
    rendered = render_all()
    contact_path = HERE / "_contact-sheet.png"
    shortlist_path = HERE / "_shortlist.png"
    make_contact_sheet(rendered, contact_path)
    make_shortlist_sheet(rendered, shortlist_path)
    print(f"Wrote {len(rendered) * 2} files + 2 sheets to {HERE}")
    print(f"Contact sheet (all 7): {contact_path}")
    print(f"Shortlist sheet (3 picks): {shortlist_path}")
    for label, variant, svg_p, png_p, _ in rendered:
        print(f"  · {label} / {variant.name}: {png_p.name}, {svg_p.name}")


if __name__ == "__main__":
    main()
