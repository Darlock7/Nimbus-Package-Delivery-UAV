#!/usr/bin/env python3
"""
Nimbus Reference Poster
Dark A3 portrait portfolio PDF — run from repo root:
  python3 generate_poster.py
Output: Nimbus_Reference_Poster.pdf
"""

import io, os
from reportlab.lib.pagesizes import A3
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from PIL import Image, ImageEnhance

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.join(REPO, "Nimbus_Reference_Poster.pdf")
IMG  = lambda f: os.path.join(REPO, "assets", "images", f)
PLT  = lambda f: os.path.join(REPO, "assets", "plots", f)

# ── Palette ───────────────────────────────────────────────────────────────────
BG        = colors.HexColor('#0a0a0a')
PANEL     = colors.HexColor('#141414')
PANEL_ALT = colors.HexColor('#1c1c1c')
ROW_ALT   = colors.HexColor('#111111')
ACCENT    = colors.HexColor('#1a8cff')   # blue accent for Nimbus
WHITE     = colors.HexColor('#ffffff')
LGRAY     = colors.HexColor('#c0c0c0')
GRAY      = colors.HexColor('#888888')
DIVIDER   = colors.HexColor('#282828')

# ── Page geometry ─────────────────────────────────────────────────────────────
W, H = A3
M    = 18

HEADER_H = 78
HERO_H   = 400
STATS_H  = 76
MID_H    = 340
PLOTS_H  = 202
FOOTER_H = 48
GAP      = 8
BOT_M    = 18

footer_y = BOT_M
plots_y  = footer_y + FOOTER_H + GAP
mid_y    = plots_y  + PLOTS_H  + GAP
stats_y  = mid_y    + MID_H    + GAP
hero_y   = stats_y  + STATS_H
header_y = hero_y   + HERO_H

# ── Image helpers ─────────────────────────────────────────────────────────────

def crop_to_ratio(path, target_w, target_h, darken=0.0):
    im = Image.open(path).convert("RGB")
    sw, sh = im.size
    tr = target_w / target_h
    sr = sw / sh
    if sr > tr:
        nw = int(sh * tr)
        im = im.crop(((sw - nw) // 2, 0, (sw - nw) // 2 + nw, sh))
    else:
        nh = int(sw / tr)
        im = im.crop((0, (sh - nh) // 2, sw, (sh - nh) // 2 + nh))
    if darken > 0:
        im = ImageEnhance.Brightness(im).enhance(1.0 - darken)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    buf.seek(0)
    return ImageReader(buf)


def pil_reader(path):
    return ImageReader(path)


def draw_image_in_box(c, path, x, y, w, h, preserve=True, anchor='c'):
    try:
        c.drawImage(pil_reader(path), x, y, w, h,
                    preserveAspectRatio=preserve, mask='auto', anchor=anchor)
    except Exception as e:
        print(f"  [warn] {path}: {e}")


def gradient_bar(c, x, y, w, steps=55, max_alpha=0.95):
    for i in range(steps):
        alpha = max_alpha * (1 - i / steps)
        c.saveState()
        c.setFillColorRGB(0.04, 0.04, 0.04)
        c.setFillAlpha(alpha)
        c.rect(x, y + i * 1.5, w, 1.5, fill=1, stroke=0)
        c.restoreState()


def dark_overlay(c, x, y, w, h, alpha=0.25):
    c.saveState()
    c.setFillColorRGB(0.04, 0.04, 0.04)
    c.setFillAlpha(alpha)
    c.rect(x, y, w, h, fill=1, stroke=0)
    c.restoreState()


def section_label(c, x, y, text, bar_w=50):
    c.setFillColor(ACCENT)
    c.setFont("Helvetica-Bold", 7)
    c.drawString(x, y, text)
    c.rect(x, y - 5, bar_w, 1.5, fill=1, stroke=0)

# ── Main draw ─────────────────────────────────────────────────────────────────

def draw_poster(c):

    # Background
    c.setFillColor(BG)
    c.rect(0, 0, W, H, fill=1, stroke=0)

    # ══ HEADER ══════════════════════════════════════════════════════════════
    c.setFillColor(PANEL)
    c.rect(0, header_y, W, HEADER_H, fill=1, stroke=0)

    c.setFillColor(ACCENT)
    c.rect(0, H - 4, W, 4, fill=1, stroke=0)

    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 36)
    c.drawString(M + 4, header_y + 34, "NIMBUS")

    c.setFillColor(ACCENT)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(M + 4, header_y + 14, "PACKAGE DELIVERY UAV — SWEPT FLYING WING")

    c.setFillColor(GRAY)
    c.setFont("Helvetica", 8.5)
    c.drawRightString(W - M, header_y + 54, "MAE 155B — Aircraft Design")
    c.drawRightString(W - M, header_y + 40, "UC San Diego  ·  Spring 2026")
    c.drawRightString(W - M, header_y + 26, "6-Person Design Team")

    c.setStrokeColor(DIVIDER)
    c.setLineWidth(0.8)
    c.line(W - 190, header_y + 12, W - 190, header_y + 64)

    # ══ HERO IMAGE ══════════════════════════════════════════════════════════
    # Hero already has a dark background — use directly
    hero_reader = crop_to_ratio(IMG("Final_CAD.png"), W, HERO_H, darken=0.05)
    c.drawImage(hero_reader, 0, hero_y, W, HERO_H,
                preserveAspectRatio=False, mask='auto')

    dark_overlay(c, 0, hero_y, W, HERO_H, alpha=0.15)
    gradient_bar(c, 0, hero_y, W, steps=55, max_alpha=0.95)

    c.setFillColor(LGRAY)
    c.setFont("Helvetica", 9)
    c.drawCentredString(W / 2, hero_y + 12,
        "CMA-ES optimized  ·  XFOIL surrogate aerodynamics  "
        "·  AVL dynamic stability  ·  Flight tested Spring 2026")

    c.setFillColor(ACCENT)
    c.rect(0, stats_y + STATS_H, W, 2.5, fill=1, stroke=0)

    # ══ STATS BAR ═══════════════════════════════════════════════════════════
    c.setFillColor(PANEL)
    c.rect(0, stats_y, W, STATS_H, fill=1, stroke=0)

    stats = [
        ("2.60 kg",  "MTOW"),
        ("20 m/s",   "Cruise speed"),
        ("14.34",    "Cruise L/D"),
        ("800 g",    "Payload"),
        ("$2.70/hr", "Profit rate"),
    ]
    sw = W / len(stats)
    for i, (val, lbl) in enumerate(stats):
        cx = i * sw + sw / 2
        c.setFillColor(ACCENT)
        c.setFont("Helvetica-Bold", 21)
        c.drawCentredString(cx, stats_y + STATS_H / 2 + 6, val)
        c.setFillColor(GRAY)
        c.setFont("Helvetica", 7.5)
        c.drawCentredString(cx, stats_y + STATS_H / 2 - 13, lbl.upper())
        if i > 0:
            c.setStrokeColor(DIVIDER)
            c.setLineWidth(0.8)
            c.line(i * sw, stats_y + 12, i * sw, stats_y + STATS_H - 12)

    c.setFillColor(ACCENT)
    c.rect(0, stats_y, W, 2, fill=1, stroke=0)

    # ══ MIDDLE — LEFT: CTOL Constraint | RIGHT: Specs Table ═════════════════
    gap_inner = 8
    left_w  = W * 0.43 - M
    right_x = M + left_w + gap_inner
    right_w = W - right_x - M

    # Left panel
    c.setFillColor(PANEL)
    c.rect(M, mid_y, left_w, MID_H, fill=1, stroke=0)
    section_label(c, M + 8, mid_y + MID_H - 14, "CTOL CONSTRAINT DIAGRAM", 85)
    draw_image_in_box(c, PLT("CTOL_Constraint_Diagram.png"),
                      M + 6, mid_y + 6,
                      left_w - 12, MID_H - 30,
                      preserve=True, anchor='c')

    # Right panel — Specs table
    c.setFillColor(PANEL)
    c.rect(right_x, mid_y, right_w, MID_H, fill=1, stroke=0)
    section_label(c, right_x + 8, mid_y + MID_H - 14,
                  "KEY DESIGN PARAMETERS", 90)

    specs = [
        ("CAT", "GEOMETRY",                "",                 ""),
        ("",    "Wingspan",                "1.5715 m",         "61.9 in"),
        ("",    "Wing area",               "0.3087 m²",        "—"),
        ("",    "Aspect ratio",            "8.0",              "—"),
        ("",    "Quarter-chord sweep",     "28.3°",            "—"),
        ("",    "Root / Tip airfoil",      "E222 / E230",      "—"),
        ("",    "Geometric washout",       "−4.04°",           "Panknin"),
        ("CAT", "WEIGHTS",                 "",                 ""),
        ("",    "MTOW (loaded)",           "2.60 kg",          "—"),
        ("",    "Payload",                 "800 g",            "—"),
        ("CAT", "PERFORMANCE",             "",                 ""),
        ("",    "Cruise speed",            "20 m/s",           "44.7 mph"),
        ("",    "Stall speed (loaded)",    "13.3 m/s",         "—"),
        ("",    "Wing loading W/S",        "87.4 N/m²",        "—"),
        ("",    "Cruise L/D",              "14.34",            "—"),
        ("",    "Static thrust",           "10.2 N",           "bench-corrected"),
        ("CAT", "PROPULSION",              "",                 ""),
        ("",    "Motor",                   "SunnySky X2216 V3","1100 KV"),
        ("",    "Propeller",               "APC 10×4.7SF",     "—"),
        ("",    "Battery",                 "3S LiPo, 11.1 V",  "—"),
        ("CAT", "STABILITY",               "",                 ""),
        ("",    "Static margin (AVL)",     "4.88%",            "MAC"),
        ("",    "Short-period ωₙ / ζ",    "6.68 / 0.62",      "rad/s"),
        ("",    "Dutch roll ωₙ / ζ",      "4.24 / 0.08",      "rad/s"),
        ("CAT", "ECONOMICS",               "",                 ""),
        ("",    "Payload volume",          "5 L",              "—"),
        ("",    "Profit rate",             "$2.70 / hr",       "800 g payload"),
    ]

    pad   = 8
    col_x = [right_x + pad,
              right_x + right_w * 0.52,
              right_x + right_w * 0.78]
    row_h = 13.0
    y_tbl = mid_y + MID_H - 28

    for i, (kind, param, val, unit) in enumerate(specs):
        ry = y_tbl - i * row_h
        if ry < mid_y + 2:
            break
        if kind == "CAT":
            c.setFillColor(PANEL_ALT)
            c.rect(right_x + 2, ry - 2, right_w - 4, row_h, fill=1, stroke=0)
            c.setFillColor(ACCENT)
            c.setFont("Helvetica-Bold", 7)
            c.drawString(col_x[0], ry + 3, param)
        else:
            if i % 2 == 0:
                c.setFillColor(ROW_ALT)
                c.rect(right_x + 2, ry - 2, right_w - 4, row_h - 1, fill=1, stroke=0)
            c.setFillColor(LGRAY)
            c.setFont("Helvetica", 7.5)
            c.drawString(col_x[0], ry + 3, param)
            c.setFillColor(WHITE)
            c.setFont("Helvetica-Bold", 7.5)
            c.drawString(col_x[1], ry + 3, val)
            c.setFillColor(GRAY)
            c.setFont("Helvetica", 7)
            c.drawString(col_x[2], ry + 3, unit)

    # ══ ANALYSIS PLOTS ═══════════════════════════════════════════════════════
    n_plots  = 3
    plot_gap = 8
    pw = (W - 2 * M - (n_plots - 1) * plot_gap) / n_plots

    plots = [
        ("V-n MANEUVER ENVELOPE",    PLT("V-n_Diagram_Maneuver_Envelope.png"), None),
        ("PROFIT vs PAYLOAD WEIGHT", PLT("Profit_vs_Payload_Weight.png"),       None),
        ("AERODYNAMIC POLARS",       PLT("Lift_Curve_CL_vs_Alpha.png"),
                                     PLT("Drag_Polar_CL_vs_CD.png")),
    ]

    for i, (lbl, f1, f2) in enumerate(plots):
        px = M + i * (pw + plot_gap)
        c.setFillColor(PANEL)
        c.rect(px, plots_y, pw, PLOTS_H, fill=1, stroke=0)
        section_label(c, px + 6, plots_y + PLOTS_H - 14, lbl, 55)

        img_h = PLOTS_H - 26
        if f2 is None:
            draw_image_in_box(c, f1, px + 4, plots_y + 4,
                              pw - 8, img_h, preserve=True, anchor='c')
        else:
            half = (img_h - 4) / 2
            draw_image_in_box(c, f2, px + 4, plots_y + 4,
                              pw - 8, half, preserve=True, anchor='c')
            draw_image_in_box(c, f1, px + 4, plots_y + 6 + half,
                              pw - 8, half, preserve=True, anchor='c')

    # ══ FOOTER ══════════════════════════════════════════════════════════════
    c.setFillColor(PANEL)
    c.rect(0, footer_y, W, FOOTER_H, fill=1, stroke=0)

    c.setFillColor(ACCENT)
    c.rect(0, footer_y + FOOTER_H, W, 2, fill=1, stroke=0)

    mid_f = footer_y + FOOTER_H / 2

    c.setFillColor(LGRAY)
    c.setFont("Helvetica-Bold", 8)
    c.drawCentredString(W / 2, mid_f + 8,
        "Harshil Patel  ·  John Sigafoos  ·  Angel Ochoa  "
        "·  Juan Sanchez  ·  Sara Chowdhury  ·  Analisa Veloz")
    c.setFillColor(GRAY)
    c.setFont("Helvetica", 7)
    c.drawCentredString(W / 2, mid_f - 5,
        "MAE 155B Aircraft Design  ·  UC San Diego  ·  Spring 2026")

    c.setFillColor(ACCENT)
    c.rect(0, 0, W, BOT_M - 2, fill=1, stroke=0)
    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 6.5)
    c.drawCentredString(W / 2, 5,
        "NIMBUS  ·  PACKAGE DELIVERY UAV  ·  SWEPT FLYING WING  "
        "·  UC SAN DIEGO  ·  MAE 155B  ·  SPRING 2026")


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    c = canvas.Canvas(OUT, pagesize=A3)
    c.setTitle("Nimbus Reference Poster")
    c.setAuthor("Group 2 — MAE 155B, UC San Diego")
    c.setSubject("Package Delivery UAV — Aircraft Design Portfolio")
    draw_poster(c)
    c.showPage()
    c.save()
    print(f"Saved → {OUT}")
