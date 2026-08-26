---
name: polish
description: >
  Review git changes or a given path for simplification, optimization, and
  modern-library usage. Use for "polish", "review my changes", or asking what
  could be simplified or modernized. Not bug-hunting — that is code-review.
argument-hint: "[base ref | path]"
---

# Polish

Report-only review of the scope for quality and modernization, then apply
the findings the user selects. This does NOT hunt for bugs (use
/code-review for that) and does NOT auto-apply (unlike /simplify).

## Boundary against the other reviews

- /polish changes code in place: a better expression on the same lines.
- /clarify changes what the code is called and what the comments say.
- /shape changes where code lives, how many units it is cut into, which unit
  depends on which, and the order things sit in a file.

If a finding moves code, splits a unit, or merges two — that is /shape. If it
only renames a thing or rewrites a comment — that is /clarify. Do not report
either one here.

## 1. Get the scope

The argument decides the scope. Work out which kind it is:

- **No argument** — review `git diff HEAD` (staged + unstaged tracked changes),
  plus new untracked files from `git ls-files --others --exclude-standard`.
- **A git ref or range** (`main`, `HEAD~3`, a branch) — review `git diff <arg>`.
- **A path** (a directory or file that exists on disk) — review the whole
  content of that path, not a diff. Say so in one line before you start, so the
  user knows the scope is every file there, not just changed lines.

If the scope resolves to nothing — an empty diff, or a path with no source
files — say so and stop.

### Out-of-scope findings are wanted

A finding does not have to belong to the job the user is doing. It does not
have to touch a line the user wrote. Report it the same way.

Never hedge. Do not write "this is outside the scope of your change", "this is
pre-existing", or "unrelated to your work". The user wants those findings, and
the disclaimer only adds noise.

## 2. Look up modern patterns via context7 (REQUIRED)

context7 is mandatory whenever the scope touches an external library or
framework. Never judge "modern usage" from memory — training data lags real
APIs.

- List every external library/framework in the scope (imports/`using`/
  `require`), with its version from the lockfile/manifest (package.json,
  *.csproj, Cargo.toml, go.mod, etc.).
- For each, fetch current docs via the context7 MCP tools: `resolve-library-id`
  (library name + the question), then `query-docs` with the selected ID —
  version-specific when the version is known.
- Hard rule: every "modern-pattern" finding MUST cite what context7 returned.
  If context7 has no docs or doesn't support the suggestion, drop the finding —
  do not assert it from memory.
- Verify the suggested API exists in the installed version before reporting it.
  No hallucinated "just use X."
- Only exception: if the scope touches no external library, there is nothing to
  query — say so and skip. The simplify/optimize checks still run.

## 3. Build findings

Look for, in priority order:
1. Real simplification — collapse needless complexity, remove redundancy,
   dedupe repeated logic.
2. Optimization — only when it measurably matters; note the cost being saved.
3. Modern-library patterns — replace dated usage with the current idiom the
   library now recommends (backed by context7).

Keep to changes inside the lines you look at.

Also apply the user's own style rules as review criteria. Read them from the
global CLAUDE.md rather than from memory — they are the source of truth and
they change. Do not restate them here.

## 4. Resolve clashes before you report

Findings that fight each other read as noise and break a bulk apply. Check the
whole list before you write it out:

- Two findings that edit the same lines → keep the better one, drop the other.
- A finding the user cannot apply because another one deletes the code it edits
  → fold the two into one finding.
- Two findings that say the same thing in two files → keep them apart only when
  the user could want one and not the other.

Every reported finding must apply on its own, and the picked findings must apply
in any order. Resolve this before the report. Do not report a clash and ask the
user to sort it out.

## 5. Rank and flag

- Drop trivial nitpicks. Only report what is worth a change.
- Rank by impact: clear wins first, subjective/optional polish last.
- If nothing is worth a change, say so and stop. Do not invent a finding to
  have something to report.
- Set a confidence for every finding: H (high), M (med), L (low).
- Set a recommend flag for every finding. Recommend it when you would apply
  the change yourself: the win is real and the risk is low. Do not recommend
  a finding that is a matter of taste, changes a deliberate convention, or
  rests on an assumption you could not verify.

## 6. Report (do not code yet)

Numbered list so the user can pick.

Never print a file path above a finding. The number must start the finding, so
nothing sits above it.

Per finding, print a header line, the diff block, then a banner for every field:

    **N. [category][H|M|L][✓|✗] short title**
    ```diff
    @@ <path from the repo root>:line @@
    - <current code>
    + <proposed code>
    ```
    ========== why ==========
    <one line>
    ========== docs ==========
    <what context7 returned — modern-pattern findings only>

Header tag rules — three tags, no spaces between them, always in this order:

1. Category: `simplification`, `optimization`, or `modern-pattern`.
2. Confidence: a single letter — `H`, `M`, or `L`.
3. Recommend flag: `✓` if you recommend applying it, `✗` if you do not.

Never write "(confidence: high)" at the end of the line — the tags carry it.

The `docs` field is required for every `modern-pattern` finding. Name the
library ID and the specific thing context7 returned that backs the change. A
modern-pattern finding without it is not reportable — drop it instead.
Omit the `docs` banner for the other two categories.

Format rules:

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
- The diff block is the only place the before/after appears. Do not repeat it
  as prose.
- The `@@ path:line @@` header is the only place the location appears. Write
  the path from the repo root there. Never repeat it on the header line.
- Show only the lines that change, plus the minimum context needed to read
  them. Do not paste the whole function.
- The terminal colours `-` lines red and `+` lines green. Colouring is
  per line, so keep one logical change per finding — do not merge two unrelated
  edits into one block.
- For a pure deletion, write only `-` lines. For a pure addition, only `+`.

After the last finding, list what you reviewed and deliberately did not report,
and why — one line per class (e.g. "generated files", "calls already on the
current idiom", "hot loops already measured"). This proves the coverage was
aggressive and the edits selective.

End with: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 7. Apply selected

Apply only the findings the user picks.

### Selection words

- **numbers** (`1,3,5`) — exactly those findings.
- **all** — every finding in the report, `✓` and `✗` alike. "all" never means
  "recommended". Never drop a finding because you did not recommend it, and
  never tell the user that "all" skips something.
- **recommended** — every finding tagged `✓`, nothing tagged `✗`.
- **none** — apply nothing.

### Rules

- Make exactly the proposed change, nothing extra.
- Change only the lines a finding names. Do not reformat, re-indent, or
  re-wrap anything else.
- Keep the file's existing conventions: line endings, indent character, and
  final newline. Read the file's current state before you write it back.

## 8. Verify

- After applying, run the project's formatter and linter if it has them
  (check the repo config for the tool it uses), and confirm every changed file
  still parses, compiles, or passes its tests. Report the command and its
  result.
- If a check fails, fix it or revert that finding. Never report the work as
  done with a failing check.
