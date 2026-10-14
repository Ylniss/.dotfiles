"""Render a flow-diagram JSON spec (../references/spec-format.md) to one SVG file. Standard library only."""
import json
import re
import sys
from pathlib import Path
from xml.sax.saxutils import escape

SANS = "Segoe UI, Helvetica, Arial, sans-serif"
MONO = "Cascadia Mono, Consolas, Menlo, monospace"
FONT_SIZE = 12.5
LINE_H = 17

PAGE_MARGIN = 30
CONTENT_W = 1440
PAGE_W = PAGE_MARGIN * 2 + CONTENT_W
SECTION_GAP = 28

INK = "#0f172a"
MUTED = "#475569"
CODE_COLOR = "#9f1239"
EVENT = "#c2410c"
ERR = "#dc2626"
HTTP = "#1d4ed8"

# name -> (stroke, fill)
PALETTE = {
    "blue": ("#2563eb", "#dbeafe"),
    "violet": ("#7c3aed", "#ede9fe"),
    "green": ("#15803d", "#dcfce7"),
    "amber": ("#b45309", "#fef3c7"),
    "cyan": ("#0e7490", "#cffafe"),
    "slate": ("#475569", "#e2e8f0"),
    "pink": ("#be185d", "#fce7f3"),
    "red": ("#b91c1c", "#fee2e2"),
}
NOTE_COLORS = ("#d97706", "#fffbeb")

# kind -> (line color, dash, filled head, label color, line width)
ARROWS = {
    "http": (HTTP, "", True, INK, 2),
    "call": (INK, "", True, INK, 1.4),
    "ret": (MUTED, ' stroke-dasharray="6 4"', False, MUTED, 1.4),
    "event": (EVENT, ' stroke-dasharray="3 3"', False, EVENT, 1.4),
    "err": (ERR, ' stroke-dasharray="6 4"', False, ERR, 1.4),
}


class SpecError(Exception):
    pass


# ---------------------------------------------------------------- text

def char_w(style, size):
    if style == "code":
        return (size - 1) * 0.6
    if style == "bold":
        return size * 0.58
    return size * 0.53


def atoms(text):
    """Split one paragraph into (word, style) atoms; a `code` span stays one atom."""
    out = []
    for part in re.split(r"(`[^`]*`|\*\*[^*]*\*\*)", text):
        if not part:
            continue
        if part.startswith("`"):
            out.append((part[1:-1], "code"))
            continue
        style = "bold" if part.startswith("**") else "text"
        inner = part[2:-2] if style == "bold" else part
        out.extend((w, "space" if w == " " else style) for w in re.split("( )", inner) if w)
    return out


def atom_w(a, size):
    return len(a[0]) * char_w(a[1], size)


def words(para):
    """Group atoms between spaces, so a line never breaks inside "`code`," or "(`code`)"."""
    out, word = [], []
    for a in atoms(para):
        if a[1] != "space":
            word.append(a)
        elif word:
            out.append(word)
            word = []
    if word:
        out.append(word)
    return out


def wrap(text, max_w, size=FONT_SIZE):
    space_w = char_w("text", size)
    lines = []
    for para in text.split("\n"):
        line, w = [], 0.0
        for word in words(para):
            word_w = sum(atom_w(a, size) for a in word)
            if line and w + space_w + word_w > max_w:
                lines.append(line)
                line, w = [], 0.0
            if line:
                line.append((" ", "space"))
                w += space_w
            line.extend(word)
            w += word_w
        lines.append(line)
    return lines


def line_w(line):
    return sum(atom_w(a, FONT_SIZE) for a in line)


def runs(line):
    out = []
    for t, s in line:
        st = "text" if s == "space" else s
        if out and out[-1][1] == st and st != "code":
            out[-1][0] += t
        else:
            out.append([t, st])
    return out


def text_svg(lines, x, y, anchor="start", size=FONT_SIZE, color=INK, halo=False, weight=None):
    halo_attr = ' stroke="#ffffff" stroke-width="4" stroke-linejoin="round" paint-order="stroke"' if halo else ""
    weight_attr = f' font-weight="{weight}"' if weight else ""
    out = []
    for i, line in enumerate(lines):
        spans = []
        for t, s in runs(line):
            t = escape(t)
            if s == "code":
                spans.append(f'<tspan font-family="{MONO}" font-size="{size - 1}" fill="{CODE_COLOR}">{t}</tspan>')
            elif s == "bold":
                spans.append(f'<tspan font-weight="700">{t}</tspan>')
            else:
                spans.append(t)
        out.append(f'<text x="{x:.1f}" y="{y + i * LINE_H:.1f}" text-anchor="{anchor}" font-family="{SANS}" '
                   f'font-size="{size}" fill="{color}" xml:space="preserve"{halo_attr}{weight_attr}>{"".join(spans)}</text>')
    return "\n".join(out)


def card(x, y, w, bottom):
    return (f'<rect x="{x}" y="{y:.1f}" width="{w}" height="{bottom - y:.1f}" rx="14" fill="#ffffff" '
            f'stroke="#cbd5e1" stroke-width="1.2"/>')


def note_box(x0, y0, x1, text):
    lines = wrap(text, x1 - x0 - 30)
    h = len(lines) * LINE_H + 12
    stroke, fill = NOTE_COLORS
    fold = 10
    svg = (f'<path d="M{x0:.1f},{y0:.1f} H{x1 - fold:.1f} L{x1:.1f},{y0 + fold:.1f} V{y0 + h:.1f} H{x0:.1f} Z" '
           f'fill="{fill}" stroke="{stroke}" stroke-width="1.2"/>'
           f'<path d="M{x1 - fold:.1f},{y0:.1f} V{y0 + fold:.1f} H{x1:.1f}" fill="none" stroke="{stroke}" '
           f'stroke-width="1.2"/>\n' + text_svg(lines, x0 + 14, y0 + 18.5))
    return svg, h


def section_heading(x, y, w, title, subtitle):
    out = [text_svg(wrap(title, w - 60, 20), x + 26, y + 34, size=20, weight=700)]
    cy = y + 58
    if subtitle:
        sl = wrap(subtitle, w - 60)
        out.append(text_svg(sl, x + 26, cy, color=MUTED))
        cy += len(sl) * LINE_H
    return out, cy


def color_of(name, where):
    if name not in PALETTE:
        raise SpecError(f"{where}: unknown color {name!r}; use one of {', '.join(PALETTE)}")
    return PALETTE[name]


def check_keys(obj, required, optional, where):
    if not isinstance(obj, dict):
        raise SpecError(f"{where}: expected an object")
    allowed = {*required, *optional}
    unknown = set(obj) - allowed
    if unknown:
        raise SpecError(f"{where}: unknown keys {sorted(unknown)}; allowed {sorted(allowed)}")
    missing = [k for k in required if k not in obj]
    if missing:
        raise SpecError(f"{where}: missing keys {missing}")


# ---------------------------------------------------------------- sections

def render_header(spec, y):
    x, w = PAGE_MARGIN, CONTENT_W
    out = [text_svg(wrap(spec["title"], w, 26), x + 4, y + 30, size=26, weight=700)]
    cy = y + 56
    if spec.get("intro"):
        il = wrap(spec["intro"], w - 10)
        out.append(text_svg(il, x + 4, cy, color=MUTED))
        cy += len(il) * LINE_H
    legend = spec.get("legend", {})
    check_keys(legend, [], ["colors", "arrows"], "legend")
    if legend.get("colors"):
        cy += 6
        lx = x + 4
        for i, item in enumerate(legend["colors"]):
            check_keys(item, ["label", "color"], [], f"legend.colors[{i}]")
            stroke, fill = color_of(item["color"], f"legend.colors[{i}]")
            label = wrap(item["label"], 600)
            bw = line_w(label[0]) + 28
            if lx + bw > x + w:
                lx, cy = x + 4, cy + 36
            out.append(f'<rect x="{lx:.1f}" y="{cy:.1f}" width="{bw:.1f}" height="26" rx="6" fill="{fill}" '
                       f'stroke="{stroke}" stroke-width="1.4"/>')
            out.append(text_svg(label, lx + 12, cy + 17.5, weight=600))
            lx += bw + 10
        cy += 26
    if legend.get("arrows"):
        cy += 22
        lx = x + 4
        for kind in ARROWS:
            if kind not in legend["arrows"]:
                continue
            color, dash, _, _, width = ARROWS[kind]
            label = wrap(legend["arrows"][kind], 600)
            if lx + 56 + line_w(label[0]) > x + w:
                lx, cy = x + 4, cy + 26
            out.append(f'<line x1="{lx}" y1="{cy}" x2="{lx + 46}" y2="{cy}" stroke="{color}" stroke-width="{width}"'
                       f'{dash} marker-end="url(#m-{kind})"/>')
            out.append(text_svg(label, lx + 56, cy + 4.5))
            lx += 56 + line_w(label[0]) + 34
        unknown = set(legend["arrows"]) - set(ARROWS)
        if unknown:
            raise SpecError(f"legend.arrows: unknown kinds {sorted(unknown)}; allowed {list(ARROWS)}")
    return "\n".join(out), cy + 20


def render_steps(sec, y, where):
    check_keys(sec, ["type", "title", "steps"], ["subtitle", "note"], where)
    x, w = PAGE_MARGIN, CONTENT_W
    out, cy = section_heading(x, y, w, sec["title"], sec.get("subtitle"))
    steps = sec["steps"]
    n = len(steps)
    gap = 34
    bw = (w - 52 - (n - 1) * gap) / n
    by = cy + 12
    step_lines = []
    for i, step in enumerate(steps):
        check_keys(step, ["title", "body", "color"], [], f"{where}.steps[{i}]")
        step_lines.append((wrap(step["title"], bw - 24), wrap(step["body"], bw - 24)))
    bh = max(len(t) + len(b) for t, b in step_lines) * LINE_H + 34
    bx = x + 26
    for i, (step, (tl, bl)) in enumerate(zip(steps, step_lines)):
        stroke, fill = color_of(step["color"], f"{where}.steps[{i}]")
        out.append(f'<rect x="{bx:.1f}" y="{by:.1f}" width="{bw:.1f}" height="{bh}" rx="10" fill="{fill}" '
                   f'stroke="{stroke}" stroke-width="1.6"/>')
        out.append(text_svg(tl, bx + 12, by + 24, weight=700))
        out.append(text_svg(bl, bx + 12, by + 24 + len(tl) * LINE_H + 7))
        if i < n - 1:
            ax = bx + bw
            out.append(f'<line x1="{ax + 4:.1f}" y1="{by + bh / 2:.1f}" x2="{ax + gap - 4:.1f}" y2="{by + bh / 2:.1f}" '
                       f'stroke="{INK}" stroke-width="2" marker-end="url(#m-call)"/>')
        bx += bw + gap
    cy = by + bh + 16
    if sec.get("note"):
        svg, h = note_box(x + 26, cy, x + w - 26, sec["note"])
        out.append(svg)
        cy += h + 4
    bottom = cy + 16
    out.insert(0, card(x, y, w, bottom))
    return "\n".join(out), bottom


def render_table(sec, y, where):
    check_keys(sec, ["type", "title", "columns", "rows"], ["subtitle", "notes"], where)
    x, w = PAGE_MARGIN, CONTENT_W
    out, cy = section_heading(x, y, w, sec["title"], sec.get("subtitle"))
    cy += 8
    inner_x, inner_w = x + 24, w - 48
    cols = sec["columns"]
    for i, c in enumerate(cols):
        check_keys(c, ["name", "weight"], [], f"{where}.columns[{i}]")
    total = sum(c["weight"] for c in cols)
    widths = [c["weight"] / total * inner_w for c in cols]
    hh = LINE_H + 14
    out.append(f'<rect x="{inner_x}" y="{cy:.1f}" width="{inner_w}" height="{hh}" fill="#1e293b" rx="6"/>')
    cx = inner_x
    for c, cw in zip(cols, widths):
        out.append(text_svg(wrap(c["name"], cw - 20), cx + 10, cy + 20, color="#ffffff", weight=700))
        cx += cw
    cy += hh
    for i, row in enumerate(sec["rows"]):
        if len(row) != len(cols):
            raise SpecError(f"{where}.rows[{i}]: {len(row)} cells, {len(cols)} columns")
        cells = [wrap(c, cw - 20) for c, cw in zip(row, widths)]
        rh = max(len(c) for c in cells) * LINE_H + 12
        fill = "#f8fafc" if i % 2 == 0 else "#ffffff"
        out.append(f'<rect x="{inner_x}" y="{cy:.1f}" width="{inner_w}" height="{rh:.1f}" fill="{fill}"/>')
        out.append(f'<line x1="{inner_x}" y1="{cy + rh:.1f}" x2="{inner_x + inner_w}" y2="{cy + rh:.1f}" stroke="#e2e8f0"/>')
        cx = inner_x
        for c, cw in zip(cells, widths):
            out.append(text_svg(c, cx + 10, cy + 18))
            cx += cw
        cy += rh
    cy += 14
    for note in sec.get("notes", []):
        svg, h = note_box(inner_x, cy, inner_x + inner_w, note)
        out.append(svg)
        cy += h + 10
    bottom = cy + 8
    out.insert(0, card(x, y, w, bottom))
    return "\n".join(out), bottom


class Sequence:
    def __init__(self, sec, y, where):
        check_keys(sec, ["type", "title", "participants", "steps"], ["subtitle"], where)
        self.where = where
        self.x, self.y, self.w = PAGE_MARGIN, y, CONTENT_W
        self.fg, self.bg, self.open_frames = [], [], []
        self.badge_count = 0
        self.participants = {}
        for i, p in enumerate(sec["participants"]):
            check_keys(p, ["id", "label", "color"], [], f"{where}.participants[{i}]")
            self.participants[p["id"]] = (p["label"], color_of(p["color"], f"{where}.participants[{i}]"))
        n = len(self.participants)
        if n < 2:
            raise SpecError(f"{where}: a sequence needs at least 2 participants")
        left, right = self.x + 120, self.x + self.w - 120
        lifeline_gap = (right - left) / (n - 1)
        self.lifeline_x = {pid: left + i * lifeline_gap for i, pid in enumerate(self.participants)}
        self.heading, cy = section_heading(self.x, y, self.w, sec["title"], sec.get("subtitle"))
        self.header_y = cy + 10
        self.box_w = min(lifeline_gap - 14, 230)
        self.box_h = max(len(wrap(label, self.box_w - 16)) for label, _ in self.participants.values()) * LINE_H + 14
        self.cursor_y = self.header_y + self.box_h + 22
        for i, s in enumerate(sec["steps"]):
            self.step(s, f"{where}.steps[{i}]")
        if self.open_frames:
            raise SpecError(f"{where}: {len(self.open_frames)} frame(s) not closed with an end step")

    def lifeline_x_of(self, pid, where):
        if pid not in self.lifeline_x:
            raise SpecError(f"{where}: unknown participant {pid!r}; known {list(self.lifeline_x)}")
        return self.lifeline_x[pid]

    def step(self, s, where):
        if "from" in s:
            check_keys(s, ["from", "to", "text"], ["kind"], where)
            kind = s.get("kind", "call")
            if kind not in ARROWS:
                raise SpecError(f"{where}: unknown kind {kind!r}; allowed {list(ARROWS)}")
            self.msg(self.lifeline_x_of(s["from"], where), self.lifeline_x_of(s["to"], where), s["text"], kind)
        elif "act" in s:
            check_keys(s, ["act", "text"], ["max_width"], where)
            self.act(s["act"], s["text"], s.get("max_width", 400), where)
        elif "note" in s:
            check_keys(s, ["note", "text"], ["pad"], where)
            over = s["note"]
            if not isinstance(over, list) or not 1 <= len(over) <= 2:
                raise SpecError(f"{where}: note takes a list of 1 or 2 participant ids")
            self.note([self.lifeline_x_of(p, where) for p in over], s["text"], s.get("pad", 90))
        elif "frame" in s:
            check_keys(s, ["frame", "cond"], [], where)
            self.open_frames.append({"tag": s["frame"], "y": self.cursor_y, "elses": [], "cond": s["cond"]})
            self.cursor_y += 34
        elif "else" in s:
            check_keys(s, ["else"], [], where)
            if not self.open_frames:
                raise SpecError(f"{where}: else outside a frame")
            self.open_frames[-1]["elses"].append((self.cursor_y + 2, s["else"]))
            self.cursor_y += 30
        elif "end" in s:
            check_keys(s, ["end"], [], where)
            if not self.open_frames:
                raise SpecError(f"{where}: end without an open frame")
            self.end()
        elif "space" in s:
            check_keys(s, ["space"], [], where)
            self.cursor_y += s["space"]
        else:
            raise SpecError(f"{where}: a step needs one of from / act / note / frame / else / end / space")

    def badge(self, cx, cy):
        self.badge_count += 1
        return (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="9" fill="#ffffff" stroke="{INK}" stroke-width="1.2"/>'
                f'<text x="{cx:.1f}" y="{cy + 4:.1f}" text-anchor="middle" font-family="{SANS}" font-size="10.5" '
                f'font-weight="700" fill="{INK}">{self.badge_count}</text>')

    def msg(self, from_x, to_x, text, kind):
        d = 1 if to_x > from_x else -1
        span = abs(to_x - from_x)
        room = (self.x + self.w - 20 - from_x) if d == 1 else (from_x - self.x - 20)
        lines = wrap(text, max(span - 40, min(room - 30, 560)))
        lw = max(line_w(l) for l in lines)
        self.cursor_y += len(lines) * LINE_H
        ay = self.cursor_y + 2
        color, dash, _, label_color, width = ARROWS[kind]
        if lw <= span - 40:
            tx, anchor = (from_x + to_x) / 2, "middle"
        else:
            # longer than the arrow: start at the sender and run past the receiver
            tx, anchor = from_x + d * 26, "start" if d == 1 else "end"
        self.fg.append(text_svg(lines, tx, ay - 6 - (len(lines) - 1) * LINE_H, anchor, color=label_color, halo=True))
        self.fg.append(f'<line x1="{from_x:.1f}" y1="{ay:.1f}" x2="{to_x - d * 2:.1f}" y2="{ay:.1f}" stroke="{color}" '
                       f'stroke-width="{width}"{dash} marker-end="url(#m-{kind})"/>')
        self.fg.append(self.badge(from_x + d * 13, ay))
        self.cursor_y = ay + 16

    def act(self, pid, text, max_w, where):
        cx = self.lifeline_x_of(pid, where)
        stroke, fill = self.participants[pid][1]
        lines = wrap(text, max_w - 22)
        w = max(line_w(l) for l in lines) + 26
        h = len(lines) * LINE_H + 12
        x0 = min(max(cx - w / 2, self.x + 14), self.x + self.w - 14 - w)
        self.fg.append(f'<rect x="{x0:.1f}" y="{self.cursor_y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="7" fill="{fill}" '
                       f'stroke="{stroke}" stroke-width="1.2"/>')
        self.fg.append(text_svg(lines, x0 + 13, self.cursor_y + 18.5))
        self.cursor_y += h + 12

    def note(self, xs, text, pad):
        x0 = max(min(xs) - pad, self.x + 14)
        x1 = min(max(xs) + pad, self.x + self.w - 14)
        svg, h = note_box(x0, self.cursor_y, x1, text)
        self.fg.append(svg)
        self.cursor_y += h + 12

    def end(self):
        frame = self.open_frames.pop()
        inset = 12 * len(self.open_frames)
        x0 = min(self.lifeline_x.values()) - 100 + inset
        x1 = max(self.lifeline_x.values()) + 100 - inset
        y0, y1 = frame["y"], self.cursor_y + 2
        self.bg.append(f'<rect x="{x0:.1f}" y="{y0:.1f}" width="{x1 - x0:.1f}" height="{y1 - y0:.1f}" rx="4" '
                       f'fill="#f8fafc" fill-opacity="0.55" stroke="#64748b" stroke-width="1.1"/>')
        tw = len(frame["tag"]) * 7.6 + 16
        self.fg.append(f'<path d="M{x0:.1f},{y0:.1f} H{x0 + tw:.1f} V{y0 + 14:.1f} L{x0 + tw - 7:.1f},{y0 + 21:.1f} '
                       f'H{x0:.1f} Z" fill="#334155"/>'
                       f'<text x="{x0 + 7:.1f}" y="{y0 + 15:.1f}" font-family="{SANS}" font-size="12" font-weight="700" '
                       f'fill="#ffffff">{escape(frame["tag"])}</text>')
        cond = wrap(f'[{frame["cond"]}]', x1 - x0 - tw - 30)
        self.fg.append(text_svg(cond[:1], x0 + tw + 10, y0 + 15, color="#334155", weight=600))
        for ey, c in frame["elses"]:
            self.bg.append(f'<line x1="{x0:.1f}" y1="{ey:.1f}" x2="{x1:.1f}" y2="{ey:.1f}" stroke="#64748b" '
                           f'stroke-width="1.1" stroke-dasharray="7 5"/>')
            self.fg.append(text_svg(wrap(f"[{c}]", x1 - x0 - 30)[:1], x0 + 10, ey + 18, color="#334155", weight=600))
        self.cursor_y = y1 + 12

    def render(self):
        bottom = self.cursor_y + 16
        out = [card(self.x, self.y, self.w, bottom + 18)]
        out.extend(self.heading)
        out.extend(self.bg)
        for pid, (label, (stroke, fill)) in self.participants.items():
            x = self.lifeline_x[pid]
            out.append(f'<line x1="{x:.1f}" y1="{self.header_y + self.box_h:.1f}" x2="{x:.1f}" y2="{bottom:.1f}" '
                       f'stroke="{stroke}" stroke-opacity="0.55" stroke-width="1.3" stroke-dasharray="5 5"/>')
            lines = wrap(label, self.box_w - 16)
            out.append(f'<rect x="{x - self.box_w / 2:.1f}" y="{self.header_y:.1f}" width="{self.box_w:.1f}" '
                       f'height="{self.box_h:.1f}" rx="8" fill="{fill}" stroke="{stroke}" stroke-width="1.6"/>')
            ty = self.header_y + (self.box_h - len(lines) * LINE_H) / 2 + 13
            out.append(text_svg(lines, x, ty, "middle", weight=600))
        out.extend(self.fg)
        return "\n".join(out), bottom + 18


def defs():
    def marker(kind, color, filled):
        path = (f'<path d="M0,0 L10,5 L0,10 z" fill="{color}"/>' if filled
                else f'<path d="M0,0 L10,5 L0,10" fill="none" stroke="{color}" stroke-width="1.6"/>')
        return (f'<marker id="m-{kind}" viewBox="0 0 10 10" refX="9.5" refY="5" markerWidth="9" markerHeight="9" '
                f'orient="auto-start-reverse" markerUnits="userSpaceOnUse">{path}</marker>')
    return "<defs>" + "".join(marker(kind, color, filled) for kind, (color, _, filled, _, _) in ARROWS.items()) + "</defs>"


def render(spec):
    check_keys(spec, ["title", "sections"], ["intro", "legend"], "spec")
    blocks = []
    svg, y = render_header(spec, 30)
    blocks.append(svg)
    y += SECTION_GAP
    renderers = {"steps": render_steps, "table": render_table,
                 "sequence": lambda sec, y, where: Sequence(sec, y, where).render()}
    for i, sec in enumerate(spec["sections"]):
        where = f"sections[{i}]"
        section_type = sec.get("type") if isinstance(sec, dict) else None
        if section_type not in renderers:
            raise SpecError(f"{where}: type must be one of {list(renderers)}")
        svg, bottom = renderers[section_type](sec, y, where)
        blocks.append(svg)
        y = bottom + SECTION_GAP
    height = round(y)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{height}" viewBox="0 0 {PAGE_W} {height}">\n'
            f'{defs()}\n<rect width="100%" height="100%" fill="#f1f5f9"/>\n' + "\n".join(blocks) + "\n</svg>\n"), height


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: render.py <spec.json> <output.svg>")
    spec = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    try:
        svg, height = render(spec)
    except SpecError as e:
        sys.exit(f"spec error: {e}")
    Path(sys.argv[2]).write_text(svg, encoding="utf-8")
    print(f"wrote {sys.argv[2]} ({PAGE_W}x{height})")


if __name__ == "__main__":
    main()
