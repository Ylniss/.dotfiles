---
name: shape
description: >
  Review git changes or a given path for code organization: units that do not
  earn their keep, duplicated logic, code in the wrong place, drift from repo
  patterns. Use for "shape", "architecture review", overengineering, or
  duplication.
argument-hint: "[base ref | path]"
---

# Shape

Report-only review of the scope for code organization, then apply the findings
the user selects. This judges where code lives and how it is cut up — not what
the lines say and not how they are written.

## Boundary against the other reviews

- /polish changes code in place: a better expression on the same lines.
- /clarify changes what the code is called and what the comments say.
- /shape changes where code lives, how many units it is cut into, which unit
  depends on which, and the order things sit in a file.

If a finding is a local rewrite of one expression, it belongs to /polish. Do not
report it here.

## 1. Get the scope

This skill judges whole files. A diff only marks which files. Never limit a
finding to the changed lines.

The argument decides which files:

- **No argument** — every file that `git diff HEAD` touches, plus new untracked
  files from `git ls-files --others --exclude-standard`.
- **A git ref or range** (`main`, `HEAD~3`, a branch) — every file that
  `git diff <arg>` touches.
- **A path** (a directory or file that exists on disk) — every source file
  under that path.

In all three cases, read and judge the whole content of each file.

If the scope resolves to nothing — no touched files, or a path with no source
files — say so and stop.

### Out-of-scope findings are wanted

A finding does not have to belong to the job the user is doing. It does not
have to touch a line the user wrote. Report it the same way.

Never hedge. Do not write "this is outside the scope of your change", "this is
pre-existing", or "unrelated to your work". The user wants those findings, and
the disclaimer only adds noise.

Every finding still names a file in the scope. The change it proposes may touch
any file in the repo.

## 2. Read the repo, judge the scope

The scope says what you judge. It does not say what you read. You cannot tell
whether a unit is worth its existence, or whether a file departs from a pattern,
by looking at the scope alone.

Before you judge anything, build a pattern brief:

- How the repo is split — the directories, the layers, what kind of thing lives
  where.
- How the repo does this kind of task in the places that already do it.
- Which way the dependencies point between the layers.
- How comparable files are organized inside — the order of members, the
  grouping, the section markers.

### Bound the reading

Read the files that compare to the ones in scope: same kind, same directory,
same layer, same task. Do not read the whole tree.

Stop as soon as you have three examples of a pattern. Three proves it (see
section 4) and the fourth teaches you nothing.

### Large scopes

When the scope holds more than about 15 files, split the work. Give each
subagent a slice of the files, the pattern brief you built, and the rules of
sections 3 and 4. Ask each for findings in the report format of section 7.

Then merge the reports yourself. Renumber into one sequence, drop the finding
two slices both found, and run section 5 over the merged list. The subagents do
not see each other, so only you can catch a clash between two slices.

## 3. Build findings

Eight categories. Every finding gets exactly one.

### overengineering

A unit that does not earn its existence: a class with one method and one caller,
a wrapper that only forwards, an interface with one implementation, a layer that
adds a hop and nothing else, an abstraction built for a second case that does
not exist.

Count the callers and give the number in the finding. A count you did not check
is not a count.

Before you report it, look for the reason the unit is there. Search the repo for
a second implementation, a test that fakes it, a framework that demands the
shape, and a registration or plugin point that needs the seam. If you find one,
it is not overengineering. If you looked and found nothing, say what you
searched for.

### duplication

The code does again what the repo already does somewhere else: a helper that
repeats an existing helper, a rule implemented twice, a constant declared in two
places.

Name the existing one with its file and line, and say how close the two are —
identical, near, or same intent.

Do not report two things that only look alike. If the two will change for
different reasons, the likeness is a coincidence, and merging them couples code
that must stay apart.

### boundary

A split that cuts one responsibility into pieces that must change together, or a
unit that fuses two responsibilities that change for different reasons.

### placement

The code works, but it sits in the wrong file, module, or directory — one whose
name or layer does not describe it.

### dependency

A unit reaches across a boundary the repo keeps: a lower layer that imports a
higher one, a new dependency that points against the direction the rest of the
repo holds, a module that pulls in something none of its siblings pull in.

### deviation

The structure departs from how the repo does the same kind of thing across
files: how it wires things up, how it names and splits its units, where it puts
this kind of code.

### layout

The organization inside one file departs from how comparable files in the repo
are organized: the order of members, the grouping, the section markers, what the
file holds.

A layout finding may propose adding a comment the repo keeps by convention — a
section marker such as `// Cleanup`. Do not propose one that only restates the
code; that fights /clarify. Report it flagged ✗ and say the convention itself is
the questionable part.

### redesign

A direction, not a move: the shape that would serve this code better, too big to
apply as one change. Report it. The user collects these and comes back to them
later.

Rules for a redesign finding:

- Always flag it ✗. It is never recommended, however good the idea is.
- Give what it buys and what it costs, one line each. An idea without a cost is
  not a proposal.
- "recommended" never applies it, because it is never ✓. "all" does apply it —
  it is a finding like any other.

## 4. Evidence rule (REQUIRED)

`deviation`, `layout`, and `dependency` findings claim the repo keeps a pattern.
Every one MUST name the places that establish it, and how many there are. A
pattern is what the repo does again and again. One other example is a
coincidence.

- Fewer than three other places follow it → drop the finding.
- Unless the repo holds fewer than three comparable places in total. Then give
  the total and report the finding at L confidence.
- Never write "the repo usually does X" without naming the files.

A `duplication` finding must name the existing implementation with its file and
line. A description of it is not enough.

`overengineering`, `boundary`, and `placement` findings need no pattern, but
they do need the counter-case search from section 3.

## 5. Resolve clashes before you report

Findings that fight each other read as noise and break a bulk apply. Check the
whole list before you write it out:

- Two findings that propose a different home for the same code → keep the better
  one, drop the other.
- A finding the user cannot apply because another one removes the code it edits
  → fold the two into one finding.
- Two findings that say the same thing in two files → keep them apart only when
  the user could want one and not the other.

Every reported finding must apply on its own, and the picked findings must apply
in any order. Resolve this before the report. Do not report a clash and ask the
user to sort it out.

## 6. Rank and flag

- Set a confidence for every finding: H (high), M (med), L (low).
- Set a recommend flag for every finding. Recommend it when you would apply the
  change yourself: the win is real and the risk is low. Do not recommend a
  finding that is a matter of taste, that breaks a convention the file keeps on
  purpose, or whose blast radius you could not check.
- Structure is where a confident guess does the most damage. When the reason for
  the current shape is not visible, that is L and ✗, not H.
- Every `redesign` finding is ✗.
- If nothing needs a change, say so and stop. Do not invent a finding to have
  something to report.

## 7. Report (do not code yet)

Give a verdict for EVERY file in the scope, in the order the files appear —
the clean ones included. Before the first file, state the file count and the
finding count in one line.

The verdict list comes first: one line per file, path and verdict, for every
file in the scope. Print the findings after it, never grouped under a file path.

Never print a file path above a finding. The number must start the finding, and
the finding header carries the path, so nothing sits between the two.

Per finding:

    **N. [category][H|M|L][✓|✗] <path from the repo root>:line — short title**
    ========== move ==========
    `current` → `proposed`
    ========== why ==========
    <one line>
    ========== pattern ==========
    <deviation, layout, dependency: the files that establish it + count>
    ========== scope ==========
    <files touched + safe/risky>

A `redesign` finding uses a different body: an `idea` field in place of `move`,
then `buys` and `costs` in place of `why`. Each keeps its own banner.

Number the findings in one sequence, in the order the files appear in the
scope, so the user can pick `7,12`.

Header tag rules — three tags, no spaces between them, always in this order:

1. Category: `overengineering`, `duplication`, `boundary`, `placement`,
   `dependency`, `deviation`, `layout`, or `redesign`.
2. Confidence: a single letter — `H`, `M`, or `L`.
3. Recommend flag: `✓` if you recommend applying it, `✗` if you do not.

Never write "(confidence: high)" at the end of the line — the tags carry it.

Format rules for the finding body:

- Wrap the header line in `**` so it reads bold. Never make it a heading — a
  heading adds a blank line under itself and breaks the tight block.
- Write every banner as `========== <label> ==========` — ten `=` on each
  side, one space around the label. Always ten, whatever the label length. Do
  not pad the banner to a fixed width and do not centre the label.
- Write no blank line inside a finding. The header line, every banner, and
  every field sit on consecutive lines. One blank line separates two findings,
  and nothing else.
- A banner is plain text. Never put it in a code fence, and never add
  backticks, bold, or a heading marker to it.
- Print the banners and the fields as plain markdown lines. Never put a finding
  inside a code fence — a fence shows the backticks as literal text and kills
  the colour.
- Wrap each side in backticks. The terminal colours both sides and leaves the
  arrow plain. Never print the backticks as literal text.
- Use a plain `→` between the two sides.
- The left side names what moves. The right side names where it ends up — a
  file, a unit, or a position. For an inline, the right side is the unit that
  absorbs it.
- Keep the `move` field to one line. Use no diff blocks; a move reads as noise
  in a diff.

End with: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 8. Apply selected

Apply only the findings the user picks.

### Selection words

- **numbers** (`1,3,5`) — exactly those findings.
- **all** — every finding in the report, `✓` and `✗` alike. "all" never means
  "recommended". Never drop a finding because you did not recommend it, and
  never tell the user that "all" skips something.
- **recommended** — every finding tagged `✓`, nothing tagged `✗`.
- **none** — apply nothing.

### Rules

- Apply them all in one pass. The result stays uncommitted for the user to read.
- Edit any file the change needs, in the scope or outside it. The scope picks
  what you judge, not what you may touch.
- Move a file with `git mv`, so its history follows it.
- Make exactly the proposed change, nothing extra. A move is no licence to
  rewrite: the lines that move keep their content.
- After a move or an inline, search the whole repo for the old location and
  confirm no reference to it remains.
- If a finding turns out to be impossible as proposed — it would break the
  build, or it needs a redesign you did not report — revert that one finding,
  finish the rest, and say which one you dropped and why.
- Change only what a finding names. Do not reformat, re-indent, or re-wrap
  anything else.
- Keep each file's existing conventions: line endings, indent character, and
  final newline. Read the file's current state before you write it back.

## 9. Verify

- Run the project's tests. Always, whenever the repo has them — find the command
  in the repo config. Report the command and its result.
- Run the project's formatter and linter if it has them, and confirm every
  changed file still parses or compiles.
- If a check fails, fix it or revert that finding. Never report the work as done
  with a failing check.
