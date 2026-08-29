---
name: prune
description: >
  Cut what does not earn its place in CLAUDE.md, AGENTS.md or a SKILL.md, then
  compress what stays. Use for "prune", "trim this file", or "what here is
  unnecessary".
argument-hint: "[path]"
---

# Prune

Report-only review of a context file, then apply the findings the user selects.
Two operations: **cut** (the content leaves this file — deleted or moved) and
**compress** (same facts, fewer words).

## Boundary against the other reviews

- /shorten compresses any text, preserving every fact. It never removes one.
- /prune decides which facts belong in *this* file at all, then compresses what
  survives.
- /shape, /polish, /clarify review code, not context files.

## 1. Get the scope

- **No argument** — `CLAUDE.md` at the repo root, plus every nested
  `CLAUDE.md` / `AGENTS.md`.
- **A path** — that file: a context file, a `SKILL.md`, or a skill's reference
  file.

Name the files and their kind in one line. If none exists, say so and stop.

## 2. The test, and the bar

One question for every line: **if it vanished, would a session do anything
differently?** Not "is it true", not "is it well written" — would the work
change. A true, well-written line that changes nothing is what this skill
removes.

How hard to press depends on how often the file loads:

| File | Loads | Bar |
|---|---|---|
| `CLAUDE.md`, `AGENTS.md` | every session | hardest — must change unrelated work |
| `SKILL.md` body | only sessions doing that task | medium — must change *this* task |
| Reference file | only when the body sends you there | loosest — detail belongs here |

From this follows the direction rule: **content flows toward the file that loads
less often.** A `SKILL.md` repeating `CLAUDE.md` is the skill's problem;
`CLAUDE.md` repeating a `SKILL.md` is `CLAUDE.md`'s. Detail a skill needs on
only some invocations belongs in its reference file, not its body.

## 3. Measure first

Print the byte count per item, sorted descending, before judging anything. Fat
concentrates in a few lines and counting finds them faster than reading. For a
bullet list:

```bash
awk '/^- \*\*/ {n=$0; sub(/^- \*\*/,"",n); sub(/\*\*.*/,"",n); printf "%5d  %s\n", length($0), n}' FILE | sort -rn
```

## 4. Cut categories

Every cut finding gets exactly one.

### discoverable

Visible from the file tree, a config or manifest file, or one grep — a directory
listing written out as prose. Project names, `.editorconfig`, the filenames
inside a folder whose name already says what it holds.

**Proof:** name the command that surfaces it, and run it.

### duplicate

The fact already reaches the session another way: a file that loads more often
(section 2), a skill that loads on demand, the tool schema, or another line of
this same file.

A summary duplicating a detailed source turns into a staleness trap the moment
it drifts — a table of three where the source now lists six. Cut it; do not fix
it.

**Proof:** name the other location and open it. "The skill probably covers this"
is not proof — read it and confirm the fact is really there.

### inconsequential

True, not duplicated, and still changes nothing. Fallbacks you would find
anyway, a pointer to a list that is already complete, an exclusion nobody would
assume otherwise.

**Proof:** state what you would do with the line, and show it is the same as
without.

### belongs-elsewhere

Right content, wrong file. Detail in a `SKILL.md` body that only some
invocations need → its reference file. A rule in `CLAUDE.md` that only one
task ever needs → the skill for that task. Project-wide truth restated in a
skill → delete, `CLAUDE.md` already carries it.

The proposed change is a move. Name the destination file.

### too-local

*Always-loaded files only.* One feature, mechanic, or subsystem described in a
section about the whole project. Test: **would this change how I approach an
_unrelated_ task?** A turn model or an input-layer stack shapes every change and
stays; one mechanic's folder split does not — a task touching it scans those
files anyway.

In a `SKILL.md`, being local is the point. Never raise this there.

### enumeration

A list where a rule is shorter *and* more correct. A list of the six places that
must be English misses the seventh; "everything written down" covers all of them
in four words. Prefer the rule whenever the list is an instance of one.

## 5. What to keep (check before cutting)

Do not cut a line that is any of these, however long:

- **Silent-failure guard** — the mistake it prevents fails quietly. "A new asset
  needs a manifest entry" prevents an asset that never loads and never warns.
- **Non-obvious runtime or control flow** — startup order, what pauses the loop,
  what the dispatch order is. Not inferable from names.
- **The why behind a surprising constraint** — why a project is excluded from
  the build, why a call blocks instead of awaiting. Without it the constraint
  looks like a bug and gets "fixed".
- **Cross-boundary routing** — a shared contract in a third project, a folder
  outside the obvious tree.
- **A decision rule between two shapes** — when A and when B. This is where an
  unguided session goes wrong most often.
- **A worked example that blocks a wrong shape** (`SKILL.md` only) — a skill
  earns the example that `CLAUDE.md` cannot afford.

Length is not the criterion. The longest item is often the one that earns its
place most.

## 6. Compress findings

For what survives, apply /shorten's techniques: merge clauses, drop filler,
imperative form, symbols (`→`, `=`, `—`), a rule in place of a list. **Zero
information loss** — a compress finding that drops a fact is a cut finding and
must be reported as one.

## 7. Resolve clashes

- Two findings on the same line → keep the better one.
- A compress finding on a line another finding cuts → drop the compress one.
- Every finding must apply on its own, in any order.

## 8. Rank and flag

- Confidence: H / M / L. Recommend flag: `✓` when you would apply it yourself.
- Flag `✗` when the cut rests on a skill you could not confirm triggers, when
  the line guards something you cannot verify, or when it is taste.
- If nothing needs a change, say so and stop. Do not invent a finding.

## 9. Report (do not edit yet)

Two lettered sections so the user can take one and not the other: **A. Cut**
(content leaves the file), **B. Compress** (nothing leaves). Number within each:
`A1`, `A2`, `B1`. Before the first finding, state the files, the finding count
and the current size in one line.

Per finding:

    **A1. [category][H|M|L][✓|✗] short title**
    ```diff
    @@ <path>:line @@
    - <current text>
    + <proposed text, or nothing for a deletion>
    ```
    ========== why ==========
    <one line: what changes if it goes>
    ========== proof ==========
    <the command run, the file opened, the location that already holds it>
    ========== saves ==========
    <bytes, and the destination file for a move>

Format rules:

- Bold the header; never a heading — a heading breaks the tight block.
- Banners are `========== <label> ==========`, ten `=` each side, plain text,
  never fenced.
- No blank line inside a finding. One blank line between findings.
- `proof` is required on `discoverable`, `duplicate` and `inconsequential`.
  Without it, drop the finding. Compress findings need no `proof`.

After the last finding, list what you reviewed and deliberately kept, one line
each, naming the rule in section 5 that saved it. That half proves the review
was aggressive rather than destructive.

End with: "Which to apply? (e.g. A1,B2 / all / recommended / none)"

## 10. Apply selected

- **A1,B2** — exactly those. **all** — every finding, `✓` and `✗` alike.
  **recommended** — every `✓`. **none** — nothing.
- Make exactly the proposed change. Do not reformat neighbouring lines.
- Keep the file's line endings, indent character and final newline.
- For a move, write the content into the destination before deleting it here.
- After a cut, re-read the section: one left-over item, or a paragraph that only
  introduced the cut line, needs the same judgment.

## 11. Verify

- Re-read the file top to bottom. It must stand alone for a session that never
  saw this conversation. For a `SKILL.md`, it must still complete its task
  without the cut lines.
- Report size before and after, with the percentage.
- Say plainly which facts now live **only** in a skill or a reference file, and
  that they reach a session only while that skill keeps triggering and the body
  keeps pointing at that reference. That is the one way this skill can quietly
  make things worse.
