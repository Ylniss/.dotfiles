# Flow diagram spec format

`scripts/render.py` lays this JSON out as one SVG page, 1500 px wide.

## Text markup

Every text field accepts:

- `` `code` `` for identifiers, routes, types, events, and fields. It renders monospace in dark red and never breaks across lines, so keep each span shorter than its box.
- `**bold**` for the one word that carries the point (`**przed**`, `**COMMIT**`).
- `\n` for a forced line break. Text also wraps on its own to fit the box or arrow.

## Top level

```json
{
  "title": "Feature name — przepływy (TICKET-123)",
  "intro": "Scope in one paragraph: what is drawn from code, what from the plan, abstraction level.",
  "legend": {
    "colors": [{ "label": "Front (apki, web)", "color": "blue" }],
    "arrows": { "http": "żądanie HTTP z aplikacji", "call": "wywołanie wewnątrz API", "ret": "odpowiedź",
                "event": "event (po commicie)", "err": "błąd / odrzucenie" }
  },
  "sections": []
}
```

`intro` and `legend` are optional. The legend lists only what you give it. Give every arrow kind the diagrams use, and one color entry per layer you color-code.

**Colors** (stroke + light fill): `blue`, `violet`, `green`, `amber`, `cyan`, `slate`, `pink`, `red`. Pick one per layer and keep it across the whole page. For example, blue = clients, one color per backend module, cyan = blob storage, slate = database, pink = events/analytics.

## Sections

Sections render top to bottom. Each one has a `type`, a `title`, and an optional `subtitle` (one or two sentences, muted text).

### `steps` — the idea in N boxes

```json
{ "type": "steps", "title": "0 · Idea w 5 krokach", "subtitle": "Wcześniej… Teraz…",
  "steps": [ { "title": "1. Apka prosi o URL", "body": "`POST files/upload-urls`\n→ podpisane URL-e", "color": "blue" } ],
  "note": "Optional yellow note under the boxes." }
```

3–6 boxes in one row joined by arrows. Body text should stay at four lines or fewer.

### `table` — case map, matrices

```json
{ "type": "table", "title": "Mapa przypadków", "subtitle": "…",
  "columns": [ { "name": "Endpoint", "weight": 30 }, { "name": "Diagram", "weight": 8 } ],
  "rows": [ [ "`POST files`", "2, 3" ] ],
  "notes": [ "Optional yellow notes under the table." ] }
```

`weight` sets relative column width. Every row must have one cell per column.

### `sequence` — a numbered sequence diagram

```json
{ "type": "sequence", "title": "3 · Wariant A — …", "subtitle": "…",
  "participants": [
    { "id": "app",   "label": "Apka SP",                  "color": "blue" },
    { "id": "files", "label": "Files `FilesService`",     "color": "violet" },
    { "id": "pub",   "label": "Azure Blob `bbox-public`", "color": "cyan" }
  ],
  "steps": [
    { "from": "app", "to": "files", "text": "`POST files { type, draft_path }`", "kind": "http" },
    { "act": "files", "text": "czy typ wolno tej roli?\ninny → 400 `OwnedFileTypeNotPublishable`", "max_width": 460 },
    { "frame": "alt", "cond": "szkic za duży" },
    { "from": "files", "to": "app", "text": "400 `ImageDraftTooLarge`", "kind": "err" },
    { "else": "OK" },
    { "from": "files", "to": "pub", "text": "upload bloba" },
    { "end": true },
    { "from": "files", "to": "app", "text": "`{ path }`", "kind": "ret" },
    { "note": ["app", "files"], "text": "Why-note spanning two lifelines.", "pad": 90 }
  ] }
```

Participants are spread evenly left to right in the order given. The renderer needs at least 2; with more than 6 the header boxes get narrow and labels wrap into three lines.

Steps, in drawing order:

| Step | Keys | Draws |
|---|---|---|
| message | `from`, `to`, `text`, `kind` (default `call`) | Numbered arrow with the label above it. A label wider than the arrow starts at the sender and runs past the receiver. |
| act | `act` (participant id), `text`, `max_width` (default 400) | A box on that lifeline in the participant's color, for internal logic, validation rules, and state changes. Use `•` bullets on separate lines. |
| note | `note` (list of 1–2 ids), `text`, `pad` (default 90) | A yellow note spanning those lifelines plus `pad` px on each side, for the WHY (an ordering that matters, a rejected alternative, a known cost) and caveats. Use `pad` 200–260 for a one-lifeline note with a long text. |
| frame | `frame` (tag: `alt`, `opt`, `loop`, or any short word), `cond` | Opens a frame around the following steps. Frames nest. |
| else | `else` (condition) | Dashed separator inside the open frame. |
| end | `end: true` | Closes the innermost frame. |
| space | `space` (px) | Vertical gap. |

Arrow kinds:

| kind | Look | Use for |
|---|---|---|
| `http` | solid blue, thick | a request from a client app or browser |
| `call` | solid dark | an in-process call, a module request, or a DB/storage write |
| `ret` | dashed grey | a response / return value |
| `event` | dotted orange | a published event (message broker, SignalR, analytics) |
| `err` | dashed red | an error response or rejection |

## Fixing what the preview shows

- A label or box spills past its border: a `code` span is too long to fit. Shorten it or split it into two spans.
- A three-line participant header: shorten the label, or drop a participant and say it in an `act`.
- Two `act` boxes in a row on the same lifeline: merge them into one with bullets.
- A note overlaps text: widen it with `pad`, or move it to the end of the diagram.
- A frame closes in the wrong place: move its `end` step. `end` closes the innermost open frame.
