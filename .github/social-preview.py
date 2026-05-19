#!/usr/bin/env python3
"""
Generates the GitHub social-preview image for project-architect.

Author: Alexander Ford <alex@pseudo-lang.com>
Repository: https://github.com/alexander-ford-ventures/project-architect
License: MIT

Usage:
    pip install pillow cairosvg
    python3 .github/social-preview.py

Output: .github/social-preview.png  (1280x640 PNG)

To regenerate on each release, run this script after bumping plugin.json,
then commit both the script change (if any) and the new social-preview.png.

Dependencies:
    - Pillow: canvas drawing, text rendering, PNG output.
    - cairosvg: rasterizes the Alexander Ford Ventures logo SVG into a PIL Image so
      it can be composited as the top-left publisher mark. Required only
      for regenerating the preview — the deployed plugin itself has zero
      runtime dependencies.

Assets:
    - .github/assets/alexander-ford-ventures-logo.svg — the source mark, three
      parallelogram-clipped rectangles filled `#1a1918`. The script
      re-tints the fill to the accent blue (`#58a6ff`) at render time so
      the mark sits cleanly on the dark canvas without needing a second
      pre-tinted copy of the SVG.

Notes on glyph substitutions:
    - v2.1.3: The top-left "▲" Unicode placeholder is replaced by the
      actual Alexander Ford Ventures logo (rasterized SVG, re-tinted to accent).
      The "Alexander Ford Ventures" wordmark text sits to the right of the logo.
    - v2.1.2: The footer right-side uses "★" (U+2605 BLACK STAR), which
      renders as a real shape out of Menlo / Arial Unicode / Apple
      Symbols (verified via PIL bbox + lit-pixel inspection).
    - The "try it →" inline CTA was replaced with a dedicated pill-shaped
      Install → button anchored to the top-right.
    - Remaining unicode glyphs in the spec (✓, →, ·) render correctly
      out of Menlo, so they are used as-is.
"""

from __future__ import annotations

import os
import sys
from io import BytesIO
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:  # pragma: no cover - import-time guard only
    sys.stderr.write(
        "error: Pillow is not installed. Install with:\n"
        "    python3 -m pip install --user pillow\n"
    )
    raise SystemExit(1) from exc

try:
    import cairosvg
except ImportError as exc:  # pragma: no cover - import-time guard only
    sys.stderr.write(
        "error: cairosvg is not installed. This script needs cairosvg to\n"
        "rasterize the Alexander Ford Ventures logo SVG. Install with:\n"
        "    python3 -m pip install --user cairosvg\n"
    )
    raise SystemExit(1) from exc


# ---------------------------------------------------------------------------
# Canvas + design tokens
# ---------------------------------------------------------------------------

WIDTH = 1280
HEIGHT = 640

# GitHub-dark-inspired palette.
COLORS = {
    "bg":       (13, 17, 23),     # #0d1117  canvas background
    "bg2":      (22, 27, 34),     # #161b22  terminal panel background
    "border":   (48, 54, 61),     # #30363d  subtle borders, grid
    "fg":       (230, 237, 243),  # #e6edf3  primary text
    "fg_muted": (139, 148, 158),  # #8b949e  secondary text
    "accent":   (88, 166, 255),   # #58a6ff  title accent, CTA
    "green":    (63, 185, 80),    # #3fb950  ✓ marks, traffic-light
    "yellow":   (210, 153, 34),   # #d29922  traffic-light caution
    "red":      (248, 81, 73),    # #f85149  traffic-light stop
}


# ---------------------------------------------------------------------------
# Font loading with robust fallbacks
# ---------------------------------------------------------------------------

# Candidate font sources. Each entry: (path, ttc-index, friendly-name).
# Loaded in order; the first one that opens wins.
SANS_REGULAR_CANDIDATES = [
    ("/System/Library/Fonts/HelveticaNeue.ttc", 0, "Helvetica Neue Regular"),
    ("/System/Library/Fonts/Helvetica.ttc",     0, "Helvetica Regular"),
    ("/System/Library/Fonts/Supplemental/Arial.ttf", 0, "Arial"),
]
SANS_BOLD_CANDIDATES = [
    ("/System/Library/Fonts/HelveticaNeue.ttc", 1, "Helvetica Neue Bold"),
    ("/System/Library/Fonts/Helvetica.ttc",     0, "Helvetica Regular (no bold)"),
    ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0, "Arial Bold"),
]
MONO_REGULAR_CANDIDATES = [
    ("/System/Library/Fonts/Menlo.ttc",   0, "Menlo Regular"),
    ("/System/Library/Fonts/Monaco.ttf",  0, "Monaco"),
    ("/System/Library/Fonts/Supplemental/Andale Mono.ttf", 0, "Andale Mono"),
    ("/System/Library/Fonts/Courier.ttc", 0, "Courier"),
]
# Used only for the small set of unicode symbols (✓, →, ·, ★) when they
# appear inside a sans-serif text run that wouldn't render them.
SYMBOL_CANDIDATES = [
    ("/System/Library/Fonts/Menlo.ttc",   0, "Menlo Regular (symbols)"),
    ("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", 0, "Arial Unicode"),
    ("/System/Library/Fonts/Apple Symbols.ttf", 0, "Apple Symbols"),
]


def _load_first(candidates: list[tuple[str, int, str]], size: int) -> tuple[ImageFont.FreeTypeFont, str]:
    """Return the first font candidate that loads, plus a friendly name."""
    last_err: Exception | None = None
    for path, idx, name in candidates:
        try:
            font = ImageFont.truetype(path, size, index=idx)
            return font, name
        except (OSError, ValueError) as exc:
            last_err = exc
            continue
    # Last-ditch fallback: PIL's built-in bitmap font. Ugly, but won't crash.
    sys.stderr.write(
        f"warning: no candidate font loaded (last error: {last_err}); "
        f"using PIL default bitmap font at size {size}\n"
    )
    return ImageFont.load_default(), "PIL default"


def load_fonts() -> dict[str, tuple[ImageFont.FreeTypeFont, str]]:
    """Load every font weight/size used by the renderer."""
    return {
        # Title block.
        "publisher":     _load_first(SANS_REGULAR_CANDIDATES, 22),  # "Alexander Ford Ventures"
        "title":         _load_first(SANS_BOLD_CANDIDATES,    92),  # "project-architect"
        "tagline":       _load_first(SANS_REGULAR_CANDIDATES, 30),

        # Terminal panel.
        "term_title":    _load_first(MONO_REGULAR_CANDIDATES, 18),  # "/project-architect"
        "term_body":     _load_first(MONO_REGULAR_CANDIDATES, 22),

        # Footer.
        "footer_mono":   _load_first(MONO_REGULAR_CANDIDATES, 22),  # repo URL
        "footer_sans":   _load_first(SANS_REGULAR_CANDIDATES, 22),  # right-side attribution
        "footer_star":   _load_first(SYMBOL_CANDIDATES,       22),  # ★ glyph in attribution

        # Top-right pill-shaped CTA: "Install →".
        "cta":           _load_first(SANS_BOLD_CANDIDATES,    26),  # "Install" label, bold
        "cta_arrow":     _load_first(SYMBOL_CANDIDATES,       26),  # → glyph in CTA
    }


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

def _measure(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    """Return (width, height) of a piece of text rendered with `font`."""
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def draw_text_run(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    segments: list[tuple[str, tuple[int, int, int], ImageFont.FreeTypeFont]],
    anchor: str = "ls",
) -> int:
    """
    Draw a sequence of (text, color, font) tuples on a single line.

    Returns the final x-coordinate after the last segment.

    Anchor "ls" = left, baseline — chosen so that mixing fonts of different
    metrics on the same line keeps the baseline aligned.
    """
    cur_x = x
    for text, color, font in segments:
        draw.text((cur_x, y), text, fill=color, font=font, anchor=anchor)
        w, _ = _measure(draw, text, font)
        cur_x += w
    return cur_x


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int],
    outline: tuple[int, int, int] | None = None,
    outline_width: int = 1,
) -> None:
    """Filled rounded rectangle with optional 1px outline."""
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=outline_width)


def draw_dot_grid(img: Image.Image, color: tuple[int, int, int], spacing: int = 24, alpha: int = 26) -> None:
    """
    Paint a subtle dot grid for a "blueprint" feel.

    The dots are blended via an alpha overlay so they sit barely above the
    background. Skipped if `alpha == 0`.
    """
    if alpha <= 0:
        return
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    dot_color = color + (alpha,)
    for gy in range(spacing, img.size[1], spacing):
        for gx in range(spacing, img.size[0], spacing):
            odraw.ellipse((gx - 1, gy - 1, gx + 1, gy + 1), fill=dot_color)
    img.alpha_composite(overlay)


# ---------------------------------------------------------------------------
# Logo (SVG) loading and tinting
# ---------------------------------------------------------------------------

# Path to the source SVG. Computed relative to this script so the generator
# stays portable (no absolute paths from the author's machine).
LOGO_SVG_PATH = Path(__file__).resolve().parent / "assets" / "alexander-ford-ventures-logo.svg"

# The source logo's fill color in its raw form. Replaced with the accent
# blue at render time so the mark stands out on the dark canvas.
LOGO_SOURCE_FILL = "#1a1918"


def load_logo(target_height_px: int, tint_hex: str) -> Image.Image:
    """
    Rasterize the Alexander Ford Ventures logo SVG to a PIL Image of approximately
    `target_height_px` pixels tall, re-tinted to `tint_hex` (e.g. '#58a6ff').

    The source SVG fills its 1024x1024 viewBox sparsely — content occupies
    roughly x=160..860, y=210..820. After rasterization we crop transparent
    margins via `getbbox()` so the logo packs tightly next to the wordmark.

    cairosvg's `parent_color` is unreliable for nested CSS classes, so we
    take the simpler-and-correct route: read the SVG as text, substitute
    the known fill color, then hand the mutated bytes to cairosvg.

    Chosen logo height: 56 px (see callsite). At this height, after content-
    bbox cropping, the visible logo is about 38 px tall — taller than the
    "Alexander Ford Ventures" 22 px text baseline by enough that it reads as a
    publisher mark, not as an inline glyph. Heights 48/52/60 were also
    tested; 56 felt the most balanced against the wordmark.
    """
    raw = LOGO_SVG_PATH.read_text(encoding="utf-8")
    # Tolerate both quoted and unquoted forms of the fill color (the source
    # file uses the `#`-prefixed form inside a CSS block; this also catches
    # any inline `fill="#1a1918"` should the SVG ever be re-exported).
    retinted = raw.replace(LOGO_SOURCE_FILL, tint_hex)

    # Render the entire 1024x1024 viewBox at the target height. Width is
    # computed proportionally (so also `target_height_px` for the square
    # viewBox). We rasterize at 2x and downscale for sharper edges, since
    # cairosvg's native rasterizer has no built-in supersampling.
    render_scale = 2
    png_bytes = cairosvg.svg2png(
        bytestring=retinted.encode("utf-8"),
        output_width=target_height_px * render_scale,
        output_height=target_height_px * render_scale,
    )
    img = Image.open(BytesIO(png_bytes)).convert("RGBA")
    if render_scale != 1:
        img = img.resize(
            (target_height_px, target_height_px),
            resample=Image.Resampling.LANCZOS,
        )

    # Crop transparent margins so the visible logo packs tightly against
    # whatever sits next to it. `getbbox()` returns the tight bbox of all
    # non-fully-transparent pixels.
    bbox = img.getbbox()
    if bbox is not None:
        img = img.crop(bbox)
    return img


# ---------------------------------------------------------------------------
# Composition
# ---------------------------------------------------------------------------

def render() -> Image.Image:
    """Render the full 1280x640 social-preview image."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), COLORS["bg"] + (255,))
    draw = ImageDraw.Draw(img)

    # Subtle dot grid for a developer-blueprint feel. Keep it very low alpha.
    draw_dot_grid(img, COLORS["border"], spacing=24, alpha=20)

    fonts = load_fonts()

    # -------------------------------------------------------------------
    # Title block (left-anchored at x = 80).
    # -------------------------------------------------------------------
    x_left = 80

    # Publisher line: [Alexander Ford Ventures logo]  Alexander Ford Ventures
    #
    # The logo is the actual SVG mark rasterized + re-tinted to accent
    # blue. Height = 56 px is tested empirically against the 22 px
    # wordmark — large enough to read as a publisher mark, small enough
    # to sit comfortably in the negative space above the 92 px title.
    publisher_text = "Alexander Ford Ventures"
    pub_font, _ = fonts["publisher"]
    # Baseline of the wordmark. Chosen so the logo and the wordmark share
    # a common visual center near y ~ 88, well clear of the title baseline
    # at y = 230 and clear of the CTA button vertically centered at y=140.
    pub_y = 100  # wordmark baseline

    logo_height_px = 56
    logo_img = load_logo(logo_height_px, tint_hex="#58a6ff")  # accent blue
    logo_w, logo_h = logo_img.size
    # Vertical center of the visible logo aligns with the visual center of
    # the wordmark line. The wordmark sits a few pixels above its baseline
    # (typographic x-height ≈ 0.5 of pt size), so we pick a center at
    # roughly pub_y - 12 and derive the top-left y from there.
    logo_cy = pub_y - 12
    logo_x = x_left
    logo_y = logo_cy - logo_h // 2
    # Composite the logo onto the canvas using its own alpha as the mask.
    img.alpha_composite(logo_img, dest=(logo_x, logo_y))

    # Wordmark to the right of the logo with a 16 px gap.
    logo_right = logo_x + logo_w
    gap_logo_to_text = 16
    text_x = logo_right + gap_logo_to_text
    draw.text(
        (text_x, pub_y),
        publisher_text,
        fill=COLORS["fg_muted"],
        font=pub_font,
        anchor="ls",
    )

    # -------------------------------------------------------------------
    # Top-right CTA: pill-shaped "Install →" button.
    # Vertically centered around y=140 (in the publisher-line negative
    # space, well clear of the title baseline at y=230). Right edge
    # aligned with the terminal panel's right edge at x=1200.
    # -------------------------------------------------------------------
    cta_font, _ = fonts["cta"]
    cta_arrow_font, _ = fonts["cta_arrow"]
    cta_label = "Install"
    cta_arrow = "→"
    # Measure the two segments and the 8px gap between them.
    cta_label_w, _ = _measure(draw, cta_label, cta_font)
    cta_arrow_w, _ = _measure(draw, cta_arrow, cta_arrow_font)
    cta_gap = 8
    cta_text_w = cta_label_w + cta_gap + cta_arrow_w
    cta_pad_x = 32
    cta_btn_h = 56
    cta_btn_w = cta_pad_x + cta_text_w + cta_pad_x
    cta_btn_right = 1200
    cta_btn_left = cta_btn_right - cta_btn_w
    cta_btn_cy = 140
    cta_btn_top = cta_btn_cy - cta_btn_h // 2
    cta_btn_bot = cta_btn_top + cta_btn_h
    cta_radius = cta_btn_h // 2  # = 28 → perfect pill
    rounded_rect(
        draw,
        (cta_btn_left, cta_btn_top, cta_btn_right, cta_btn_bot),
        radius=cta_radius,
        fill=COLORS["accent"],
        outline=COLORS["accent"],
        outline_width=1,
    )
    # Center the text vertically using the middle-baseline (ms) anchor.
    # Use the button's vertical center and let the anchor handle baseline.
    cta_text_left = cta_btn_left + cta_pad_x
    # "mm" anchor centers both horizontally and vertically.
    draw.text(
        (cta_text_left + cta_label_w // 2, cta_btn_cy),
        cta_label,
        fill=COLORS["bg"],
        font=cta_font,
        anchor="mm",
    )
    draw.text(
        (cta_text_left + cta_label_w + cta_gap + cta_arrow_w // 2, cta_btn_cy),
        cta_arrow,
        fill=COLORS["bg"],
        font=cta_arrow_font,
        anchor="mm",
    )

    # Title: "project-architect"
    title_font, _ = fonts["title"]
    title_y = 230  # baseline; large font sits above this
    draw.text((x_left, title_y), "project-architect", fill=COLORS["fg"], font=title_font, anchor="ls")

    # Tagline.
    tagline_font, _ = fonts["tagline"]
    tagline_y = 290  # baseline
    draw.text(
        (x_left, tagline_y),
        "Bootstrap any project end-to-end inside Claude Code.",
        fill=COLORS["fg_muted"],
        font=tagline_font,
        anchor="ls",
    )

    # -------------------------------------------------------------------
    # Terminal panel.
    # -------------------------------------------------------------------
    panel_box = (80, 320, 1200, 510)  # left, top, right, bottom (h = 190)
    rounded_rect(draw, panel_box, radius=12, fill=COLORS["bg2"], outline=COLORS["border"], outline_width=1)

    # Window-control dots: red, yellow, green; diameter 12, spaced 22 apart.
    # Center y ~342 (relative to panel top 320).
    dot_y = 342
    dot_radius = 6
    dot_xs = [110, 132, 154]
    dot_colors = [COLORS["red"], COLORS["yellow"], COLORS["green"]]
    for cx, color in zip(dot_xs, dot_colors):
        draw.ellipse(
            (cx - dot_radius, dot_y - dot_radius, cx + dot_radius, dot_y + dot_radius),
            fill=color,
        )

    # Window title centered horizontally inside the panel header area.
    term_title_font, _ = fonts["term_title"]
    panel_cx = (panel_box[0] + panel_box[2]) // 2
    # Use middle-baseline (mb) anchor so we set the *baseline* y.
    draw.text(
        (panel_cx, 348),
        "/project-architect",
        fill=COLORS["fg_muted"],
        font=term_title_font,
        anchor="ms",  # middle, baseline
    )

    # Terminal body — three lines at y baselines ~388, 424, 460.
    term_x = panel_box[0] + 28  # 28px padding inside the panel
    term_body_font, _ = fonts["term_body"]

    # Line 1: "$ /project-architect"
    draw_text_run(
        draw,
        term_x,
        388,
        [
            ("$", COLORS["green"], term_body_font),
            (" /project-architect", COLORS["fg"], term_body_font),
        ],
        anchor="ls",
    )

    # Line 2: "✓ Preflight passed  ·  9 phases · 5 subagents"
    draw_text_run(
        draw,
        term_x,
        424,
        [
            ("✓", COLORS["green"], term_body_font),                    # ✓
            (" Preflight passed  ·  9 phases · 5 subagents",      # · ... ·
             COLORS["fg"], term_body_font),
        ],
        anchor="ls",
    )

    # Line 3: "→ docs/, ADRs, CLAUDE.md, .claude/ config — all committed"
    draw_text_run(
        draw,
        term_x,
        460,
        [
            ("→", COLORS["accent"], term_body_font),                   # →
            (" docs/, ADRs, CLAUDE.md, .claude/ config — all committed",
             COLORS["fg"], term_body_font),
        ],
        anchor="ls",
    )

    # -------------------------------------------------------------------
    # Footer.
    # -------------------------------------------------------------------
    footer_mono_font, _ = fonts["footer_mono"]
    footer_sans_font, _ = fonts["footer_sans"]
    footer_star_font, _ = fonts["footer_star"]
    footer_y = 590  # baseline

    # Left: repo URL in mono, muted.
    draw.text(
        (80, footer_y),
        "github.com/alexander-ford-ventures/project-architect",
        fill=COLORS["fg_muted"],
        font=footer_mono_font,
        anchor="ls",
    )

    # Right: attribution. "★ Skillfully made with Claude Code".
    # The ★ glyph (U+2605 BLACK STAR) is rendered by a symbol-capable font
    # (Menlo → Arial Unicode → Apple Symbols) so it lands as a real star
    # rather than an asterisk fallback. Right-align against x=1200 to match
    # the terminal panel's right edge.
    footer_segments = [
        ("★", COLORS["accent"], footer_star_font),
        (" Skillfully made with Claude Code", COLORS["accent"], footer_sans_font),
    ]
    # Measure total width to right-align.
    total_w = 0
    for text, _, font in footer_segments:
        w, _h = _measure(draw, text, font)
        total_w += w
    footer_x_start = 1200 - total_w
    draw_text_run(draw, footer_x_start, footer_y, footer_segments, anchor="ls")

    return img


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    out_path = Path(__file__).resolve().parent / "social-preview.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        img = render()
        # Flatten the RGBA composition onto an opaque RGB canvas for a
        # smaller, GitHub-friendly PNG.
        flat = Image.new("RGB", img.size, COLORS["bg"])
        flat.paste(img, mask=img.split()[3])
        flat.save(out_path, format="PNG", optimize=True)
    except Exception as exc:  # pragma: no cover - top-level guard
        sys.stderr.write(f"error: rendering failed: {exc}\n")
        return 1

    # Relative path printed for the user.
    rel = os.path.relpath(out_path, Path.cwd())
    print(f"wrote {rel} ({WIDTH}x{HEIGHT})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
