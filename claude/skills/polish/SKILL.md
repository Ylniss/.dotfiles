---
name: polish
description: >
  Review the current git changes — or a path given as the argument — for
  simplification, optimization, and modern-library usage. Reports findings
  first, applies only the ones the user picks. Use when the user says
  "polish", "polish changes", "review my changes", or asks what could be
  simplified/improved/optimized or made to use current library patterns.
argument-hint: "[base ref | path]"
---

# Polish

Report-only review of the scope for quality and modernization, then apply
the findings the user selects. This does NOT hunt for bugs (use
/code-review for that) and does NOT auto-apply (unlike /simplify).

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

## 2. Look up modern patterns via context7 (REQUIRED)

context7 is mandatory whenever the scope touches an external library or
framework. Never judge "modern usage" from memory — training data lags real
APIs. Do not skip this even if you think you know the answer.

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

Also apply the user's own style rules as review criteria. Read them from the
global CLAUDE.md rather than from memory — they are the source of truth and
they change. Do not restate them here.

## 4. Filter and rank

- Drop trivial nitpicks. Only report what is worth a change.
- Rank by impact: clear wins first, subjective/optional polish last.
- If nothing is worth a change, say so and stop. Do not invent a finding to
  have something to report.
- Set a confidence for every finding: H (high), M (med), L (low).
- Set a recommend flag for every finding. Recommend it when you would apply
  the change yourself: the win is real and the risk is low. Do not recommend
  a finding that is a matter of taste, changes a deliberate convention, or
  rests on an assumption you could not verify.

## 5. Report (do not code yet)

Numbered list so the user can pick. Per finding, print a header line, a why
line, then a diff block:

    N. [category][H|M|L][✓|✗] file:line — short title
       why:  <one line>
       docs: <what context7 returned — modern-pattern findings only>

    ```diff
    @@ file:line @@
    - <current code>
    + <proposed code>
    ```

Header tag rules — three tags, no spaces between them, always in this order:

1. Category: `simplification`, `optimization`, or `modern-pattern`.
2. Confidence: a single letter — `H`, `M`, or `L`.
3. Recommend flag: `✓` if you recommend applying it, `✗` if you do not.

Never write "(confidence: high)" at the end of the line — the tags carry it.

The `docs:` line is required for every `modern-pattern` finding. Name the
library ID and the specific thing context7 returned that backs the change. A
modern-pattern finding without it is not reportable — drop it instead.
Omit the `docs:` line for the other two categories.

Format rules:

- The diff block is the only place the before/after appears. Do not repeat it
  as prose.
- Keep the `@@ file:line @@` header so the reader sees the location inside the
  block.
- Show only the lines that change, plus the minimum context needed to read
  them. Do not paste the whole function.
- The terminal colours `-` lines red and `+` lines green. Colouring is
  per line, so keep one logical change per finding — do not merge two unrelated
  edits into one block.
- For a pure deletion, write only `-` lines. For a pure addition, only `+`.

End with: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 6. Apply selected

- Apply only the findings the user names.
- "recommended" means every finding you tagged ✓, and nothing tagged ✗.
- Make exactly the proposed change, nothing extra.

## 7. Verify

- Change only the lines a finding names. Do not reformat, re-indent, or
  re-wrap anything else.
- Keep the file's existing conventions: line endings, indent character, and
  final newline. Read the file's current state before you write it back.
- After applying, run the project's formatter and linter if it has them
  (check the repo config for the tool it uses), and confirm every changed file
  still parses, compiles, or passes its tests. Report the command and its
  result.
- If a check fails, fix it or revert that finding. Never report the work as
  done with a failing check.
