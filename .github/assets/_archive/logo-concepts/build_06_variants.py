#!/usr/bin/env python3
# Author: Alexander Ford <alex@pseudo-lang.com>
# Repository: https://github.com/alexfordlabs/project-architect
# License: MIT
"""Render the AF/LABS stack mark across 4 fonts × 2 width strategies × 2 variants.

Fonts (display + subtext pairs):
    · geist          GeistMono-ExtraBold + GeistMono-Medium
    · inter          Inter-ExtraBold     + Inter-SemiBold
    · helvetica      Helvetica Bold      + Helvetica Regular  (TTC indexes 1, 0)
    · helveticaneue  Helvetica Neue Bold + Helvetica Neue Medium (TTC idx 1, 10)

Width strategies:
    · default        LABS at fixed size + fixed letter-spacing (classic editorial)
    · matched        LABS letter-spaced precisely so its rendered width == AF's
                     rendered width — axial alignment, more architectural

Run:
    /tmp/pdfbuild-venv/bin/python .github/assets/logo-concepts/build_06_variants.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent.parent

# ── Fonts ──────────────────────────────────────────────────────────────────
GEIST_DIR = REPO_ROOT / "docs" / "explainer" / "fonts"
FONTS = {
    "geist": {
        "display": (str(GEIST_DIR / "GeistMono-ExtraBold.ttf"), 0),
        "sub":     (str(GEIST_DIR / "GeistMono-Medium.ttf"), 0),
        "label":   "Geist Mono ExtraBold + Medium",
        "is_mono": True,
    },
    "inter": {
        "display": ("/tmp/fonts-extra/extras/ttf/Inter-ExtraBold.ttf", 0),
        "sub":     ("/tmp/fonts-extra/extras/ttf/Inter-SemiBold.ttf", 0),
        "label":   "Inter ExtraBold + SemiBold",
        "is_mono": False,
    },
    "helvetica": {
        "display": ("/System/Library/Fonts/Helvetica.ttc", 1),   # Bold
        "sub":     ("/System/Library/Fonts/Helvetica.ttc", 0),   # Regular
        "label":   "Helvetica Bold + Regular",
        "is_mono": False,
    },
    "helveticaneue": {
        "display": ("/System/Library/Fonts/HelveticaNeue.ttc", 1),   # Bold
        "sub":     ("/System/Library/Fonts/HelveticaNeue.ttc", 10),  # Medium
        "label":   "Helvetica Neue Bold + Medium",
        "is_mono": False,
    },
}

WIDTHS = ["default", "matched"]


# ── Variants (V5 palette) ──────────────────────────────────────────────────
INK_LIGHT = (10, 10, 10)
PAPER_LIGHT = (255, 255, 255)
INK_DARK = (255, 255, 255)
PAPER_DARK = (10, 10, 10)


@dataclass
class Variant:
    name: str
    ink: tuple
    paper: tuple


VARIANTS = [
    Variant("light", INK_LIGHT, PAPER_LIGHT),
    Variant("dark", INK_DARK, PAPER_DARK),
]


# ── Helpers ────────────────────────────────────────────────────────────────


def load_font(font_path, index, size):
    return ImageFont.truetype(font_path, size=size, index=index)


def measure(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return (bbox[2] - bbox[0], bbox[3] - bbox[1]), bbox


def measure_letter_spaced(draw, text, font, spacing_px):
    """Total width if `text` is rendered char-by-char with `spacing_px` between chars.
    Assumes per-char widths add cleanly (sufficient for ASCII display fonts).
    """
    total = 0
    per_char = []
    for i, ch in enumerate(text):
        bb = draw.textbbox((0, 0), ch, font=font)
        cw = bb[2] - bb[0]
        per_char.append((ch, cw, bb))
        total += cw
        if i < len(text) - 1:
            total += spacing_px
    # Add right-side bearing adjustment from the very last char
    return total, per_char


def render_letter_spaced(draw, text, font, x, y, spacing_px, fill):
    """Render text with manual letter-spacing.

    `x, y` is the top-left of the FIRST glyph's draw origin (NOT the bbox origin).
    Honours each glyph's left-side bearing so the result reads cleanly.
    """
    pen_x = x
    for i, ch in enumerate(text):
        bb = draw.textbbox((0, 0), ch, font=font)
        draw.text((pen_x - bb[0], y), ch, font=font, fill=fill)
        cw = bb[2] - bb[0]
        pen_x += cw
        if i < len(text) - 1:
            pen_x += spacing_px


def find_spacing_for_target_width(draw, text, font, target_w):
    """Binary search a letter-spacing value (px) so that `text` rendered with
    that spacing has total rendered width ≈ target_w.
    """
    lo, hi = 0, 400
    for _ in range(40):
        mid = (lo + hi) / 2.0
        w, _ = measure_letter_spaced(draw, text, font, mid)
        if w < target_w:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2.0


# ── Renderer ───────────────────────────────────────────────────────────────


def render_af_labs(font_key, width_mode, variant):
    """Render one variant: returns PIL Image."""
    size = 1024
    img = Image.new("RGB", (size, size), variant.paper)
    draw = ImageDraw.Draw(img)

    cfg = FONTS[font_key]
    display_font = load_font(cfg["display"][0], cfg["display"][1], 520)
    sub_size = 88
    sub_font = load_font(cfg["sub"][0], cfg["sub"][1], sub_size)

    # ── AF measurements ──
    af_text = "AF"
    (af_w, af_h), af_bbox = measure(draw, af_text, display_font)
    af_x = (size - af_w) // 2 - af_bbox[0]
    af_y = int(size * 0.34) - af_h // 2 - af_bbox[1]
    draw.text((af_x, af_y), af_text, font=display_font, fill=variant.ink)

    # ── LABS — width strategy ──
    labs_text = "LABS"
    if width_mode == "default":
        spacing = 22 if cfg["is_mono"] else 18
        labs_w, per_char = measure_letter_spaced(draw, labs_text, sub_font, spacing)
        rule_extent_w = max(labs_w + 80, af_w * 0.6)
    else:  # matched
        spacing = find_spacing_for_target_width(draw, labs_text, sub_font, af_w)
        labs_w, per_char = measure_letter_spaced(draw, labs_text, sub_font, spacing)
        rule_extent_w = af_w   # rule matches AF (and LABS) width exactly

    # ── Hairline rule between AF and LABS ──
    rule_y = int(size * 0.66)
    rule_x_left = (size - rule_extent_w) // 2
    rule_x_right = rule_x_left + rule_extent_w
    draw.rectangle([rule_x_left, rule_y, rule_x_right, rule_y + 3], fill=variant.ink)

    # ── LABS render ──
    labs_x = (size - labs_w) // 2
    labs_y = rule_y + 52
    render_letter_spaced(draw, labs_text, sub_font, labs_x, labs_y,
                         spacing, variant.ink)

    return img


# ── Comparison sheet ────────────────────────────────────────────────────────


def build_comparison_sheet(rendered, outpath):
    """4 rows (fonts) × 4 cols (default-light, default-dark, matched-light,
    matched-dark)."""
    font_keys = list(FONTS.keys())
    cell_w, cell_h = 420, 420
    gutter = 14
    margin_x = 60
    margin_y = 70
    label_w = 220              # left-side column showing font label
    col_label_h = 60           # column header
    total_w = margin_x * 2 + label_w + cell_w * 4 + gutter * 3
    total_h = margin_y * 2 + col_label_h + (cell_h + 36) * len(font_keys) + 80

    sheet = Image.new("RGB", (total_w, total_h), (245, 245, 247))
    draw = ImageDraw.Draw(sheet)

    title_font = load_font(str(GEIST_DIR / "GeistMono-ExtraBold.ttf"), 0, 50)
    sub_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 22)
    label_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 18)
    col_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 18)

    # Header
    title = "AF / LABS — FONT × WIDTH MATRIX"
    tb = draw.textbbox((0, 0), title, font=title_font)
    tw = tb[2] - tb[0]
    draw.text(
        ((total_w - tw) // 2 - tb[0], 30),
        title,
        font=title_font,
        fill=(10, 10, 10),
    )
    sub = "4 fonts · default vs matched-width · light + dark · alexfordlabs.com"
    sb = draw.textbbox((0, 0), sub, font=sub_font)
    sw = sb[2] - sb[0]
    draw.text(
        ((total_w - sw) // 2 - sb[0], 90),
        sub,
        font=sub_font,
        fill=(85, 94, 120),
    )

    # Column headers
    col_headers = [
        ("DEFAULT", "LIGHT"),
        ("DEFAULT", "DARK"),
        ("MATCHED-WIDTH", "LIGHT"),
        ("MATCHED-WIDTH", "DARK"),
    ]
    grid_left = margin_x + label_w
    grid_top = 150
    for i, (mode, var) in enumerate(col_headers):
        cell_x = grid_left + i * (cell_w + gutter)
        draw.text((cell_x + 8, grid_top), mode, font=col_font, fill=(10, 10, 10))
        # Smaller variant tag
        draw.text((cell_x + 8, grid_top + 24), var, font=label_font, fill=(85, 94, 120))
        # Hairline divider rule below column header
        draw.rectangle(
            [cell_x, grid_top + col_label_h - 4, cell_x + cell_w, grid_top + col_label_h - 3],
            fill=(180, 180, 184),
        )

    # Rows
    rows_top = grid_top + col_label_h + 10
    cell_keys = [(m, v) for m in ["default", "matched"] for v in ["light", "dark"]]
    for r, font_key in enumerate(font_keys):
        row_y = rows_top + r * (cell_h + 36)
        # Row label (font family)
        draw.text(
            (margin_x, row_y + cell_h // 2 - 12),
            FONTS[font_key]["label"],
            font=label_font,
            fill=(10, 10, 10),
        )
        for c, (mode, var) in enumerate(cell_keys):
            cell_x = grid_left + c * (cell_w + gutter)
            paper = PAPER_LIGHT if var == "light" else PAPER_DARK
            draw.rectangle(
                [cell_x, row_y, cell_x + cell_w, row_y + cell_h],
                fill=paper,
                outline=(210, 210, 214),
                width=1,
            )
            img = rendered[(font_key, mode, var)]
            pad = 24
            iw, ih = img.size
            scale = min((cell_w - pad * 2) / iw, (cell_h - pad * 2) / ih)
            new_w, new_h = int(iw * scale), int(ih * scale)
            resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            px = cell_x + (cell_w - new_w) // 2
            py = row_y + (cell_h - new_h) // 2
            sheet.paste(resized, (px, py))

    # Footer note
    foot = "Original Geist Mono ExtraBold default-light = the previously chosen baseline · row 1, col 1"
    fb = draw.textbbox((0, 0), foot, font=label_font)
    fw = fb[2] - fb[0]
    draw.text(
        ((total_w - fw) // 2 - fb[0], total_h - margin_y + 10),
        foot,
        font=label_font,
        fill=(85, 94, 120),
    )

    sheet.save(outpath, optimize=True)
    return outpath


def build_finalists_sheet(rendered, outpath):
    """Focused 3-font finalists sheet — Geist Mono, Inter, Helvetica Neue,
    matched-width only, big readable cells."""
    finalist_keys = ["geist", "inter", "helveticaneue"]
    finalist_titles = {
        "geist":         ("GEIST MONO EXTRABOLD",
                          "Most technical / CLI-coded · Pseudo brand sibling"),
        "inter":         ("INTER EXTRABOLD",
                          "Most modern-startup · contemporary venture-design feel"),
        "helveticaneue": ("HELVETICA NEUE BOLD",
                          "Most timeless · Swiss / institutional / long-shelf-life"),
    }
    cell_w, cell_h = 760, 760
    gutter = 28
    margin = 70
    label_h = 84
    cols = 2  # light · dark
    rows = len(finalist_keys)
    total_w = margin * 2 + cell_w * cols + gutter * (cols - 1)
    total_h = margin * 2 + (cell_h + label_h + gutter) * rows + 40

    sheet = Image.new("RGB", (total_w, total_h), (245, 245, 247))
    draw = ImageDraw.Draw(sheet)

    title_font = load_font(str(GEIST_DIR / "GeistMono-ExtraBold.ttf"), 0, 56)
    sub_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 26)
    label_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 22)
    desc_font = load_font(str(GEIST_DIR / "GeistMono-Medium.ttf"), 0, 19)

    # Header
    title = "AF / LABS — FINALISTS  ·  MATCHED-WIDTH"
    tb = draw.textbbox((0, 0), title, font=title_font)
    tw = tb[2] - tb[0]
    draw.text(((total_w - tw) // 2 - tb[0], 36), title,
              font=title_font, fill=(10, 10, 10))
    sub = "3 fonts · light + dark · alexfordlabs.com"
    sb = draw.textbbox((0, 0), sub, font=sub_font)
    sw = sb[2] - sb[0]
    draw.text(((total_w - sw) // 2 - sb[0], 110), sub,
              font=sub_font, fill=(85, 94, 120))

    grid_top = 180

    for r, font_key in enumerate(finalist_keys):
        row_y = grid_top + r * (cell_h + label_h + gutter)
        ctitle, csub = finalist_titles[font_key]
        # Font label (top-left of row)
        draw.text((margin, row_y), ctitle,
                  font=label_font, fill=(10, 10, 10))
        # Description (top-right of row)
        db = draw.textbbox((0, 0), csub, font=desc_font)
        dw = db[2] - db[0]
        draw.text((total_w - margin - dw - db[0], row_y + 4), csub,
                  font=desc_font, fill=(85, 94, 120))
        cells_top = row_y + label_h - 16

        for c, variant in enumerate(VARIANTS):
            cell_x = margin + c * (cell_w + gutter)
            draw.rectangle(
                [cell_x, cells_top, cell_x + cell_w, cells_top + cell_h],
                fill=variant.paper,
                outline=(210, 210, 214),
                width=1,
            )
            img = rendered[(font_key, "matched", variant.name)]
            pad = 28
            iw, ih = img.size
            scale = min((cell_w - pad * 2) / iw, (cell_h - pad * 2) / ih)
            new_w, new_h = int(iw * scale), int(ih * scale)
            resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            px = cell_x + (cell_w - new_w) // 2
            py = cells_top + (cell_h - new_h) // 2
            sheet.paste(resized, (px, py))

    sheet.save(outpath, optimize=True)
    return outpath


def main():
    rendered = {}
    for font_key in FONTS.keys():
        for mode in WIDTHS:
            for variant in VARIANTS:
                img = render_af_labs(font_key, mode, variant)
                rendered[(font_key, mode, variant.name)] = img
                stem = f"concept-06-af-labs-{font_key}-{mode}-{variant.name}"
                img.save(HERE / f"{stem}.png", optimize=True)

    matrix_path = build_comparison_sheet(rendered, HERE / "_06-font-width-matrix.png")
    finalists_path = build_finalists_sheet(rendered, HERE / "_06-finalists.png")
    print(f"Wrote {len(rendered)} PNG variants + 2 sheets")
    print(f"Matrix sheet:    {matrix_path}")
    print(f"Finalists sheet: {finalists_path}")


if __name__ == "__main__":
    main()
