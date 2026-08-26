---
name: clarify
description: >
  Review git changes or a given path for comment essence and name
  directness. Use for "clarify", tightening comments, or improving naming.
argument-hint: "[base ref | path]"
---

# Clarify

Report-only review of the scope for clear comments and direct names, then
apply the findings the user selects. Quality only — no logic changes.

## Boundary against the other reviews

- /polish changes code in place: a better expression on the same lines.
- /clarify changes what the code is called and what the comments say.
- /shape changes where code lives, how many units it is cut into, which unit
  depends on which, and the order things sit in a file.

If a finding rewrites logic, that is /polish. If it moves code, splits a unit,
or merges two — that is /shape. Do not report either one here.

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

## 2. Review comments

Goal: every comment is essence only — simple words, direct, no fluff, no
mental leap to understand it.

Evaluate EVERY comment in the scope — do not sample or cherry-pick. Each comment
gets one of these verdicts: keep as-is / shorten / reword / delete. Aggressive
coverage, selective edits — report only what needs a change.

Apply these, in priority order:

- Shorten verbose comments to their core point.
- Plain wording — replace jargon, insider shorthand, and domain slang with
  everyday words (e.g. "flake the suite" → "break the tests"). Keep the meaning;
  just change the vocabulary so any reader gets it with no mental leap.
- A comment that just restates what the code already says → propose DELETE,
  not shorten. A redundant comment is worse than none.
- Redundant with the name → DELETE. A clear name (class, method, variable) plus
  an obvious body often already says everything the comment does. Cover test:
  hide the comment — can a reader still tell what's going on from the name and
  code alone? If yes, the comment is noise; delete it. (Also check the usage
  site: if the WHY is already stated where the thing is wired up, the definition
  doesn't need to repeat it.) Prefer a clearer name over keeping a comment.
- Do NOT touch: TODO comments, license/legal headers, API-contract doc
  comments (params/returns/throws), and comments explaining a non-obvious WHY.

## 3. Review names

Goal: no mental leap to know what a name represents. Direct and unambiguous —
NOT merely longer.

Evaluate EVERY name declared in the scope — do not sample or cherry-pick. That
means all of: local variables, fields, properties, parameters, constants,
functions, methods, classes, types, interfaces, enums and their members,
modules, and files. Each name gets one verdict: keep / rename. Report every
rename; report nothing for a name you keep. Aggressive coverage, selective
edits.

### Judge in context, not on the declaration line

For each name, read how it is used before you judge it:

- Read the use sites. The name is wrong when what it holds or does there does
  not match what the name says.
- Read the value it takes. A name that says less than the value carries (or
  more) is a rename.
- Check the scope and lifetime. A short name is fine in a three-line block and
  too vague at file or public scope.
- Check the neighbours. A name must not overlap in meaning with a sibling name
  in the same type, function, or parameter list.
- Check the caller's vocabulary. Use the word the surrounding code and the
  domain already use for that concept.

### Rename when the name is

- Misleading — implies the wrong thing. Highest priority; worse than vague.
- Vague — too short or generic to convey meaning (`d`, `tmp`, `data`, `mgr`).
- Over-verbose — longer than needed without adding clarity.
- Inconsistent — a different word for a concept the surrounding code already
  names.
- Beatable — a better word exists that removes a mental leap. Report this even
  when the current name is not wrong. Do not stop at "acceptable"; if you can
  phrase it better, propose it and let the user decide.

### Constraints

- Match the naming conventions already used in the surrounding code.
- For every rename, note the blast radius: how many references it touches and
  whether it crosses a file or public/exported boundary (safe vs risky).
- If a rename makes a nearby comment redundant, note that too.

## 4. Rank and flag

- Set a confidence for every finding: H (high), M (med), L (low).
- Set a recommend flag for every finding. Recommend it when you would apply
  the change yourself: the win is real and the risk is low. Do not recommend a
  finding that is a matter of taste, that breaks a convention the file keeps on
  purpose, or whose blast radius you could not check.
- The recommend flag is the brake on the "Beatable" rule. Report the marginal
  rename, but flag it ✗. Never inflate the ✓ list to look thorough.
- If nothing needs a change, say so and stop. Do not invent a finding to have
  something to report.

## 5. Report (do not code yet)

List the findings in one numbered sequence, in the order the files appear in
the scope, so the user can pick `7,12`. Before the first finding, state the
finding count and the file count in one line.

Never print a file path above a finding. The number must start the finding, so
nothing sits above it.

Per finding, print a header line, the diff block, then a banner for every field:

    **N. [comment|name][H|M|L][✓|✗] short title**
    ```diff
    @@ <path from the repo root>:line @@
    - <current code>
    + <proposed code>
    ```
    ========== why ==========
    <one line>
    ========== scope ==========
    <only for renames: ref count + safe/risky>

Header tag rules — three tags, no spaces between them, always in this order:

1. Kind: `comment` or `name`.
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
- Print the banners and the fields as plain markdown lines. The diff block is
  the only fence in a finding.
- The diff block is the only place the before and after text appears. Do not
  repeat it as prose.
- The `@@ path:line @@` header is the only place the location appears. Write
  the path from the repo root there. Never repeat it on the header line.
- Show only the lines that change, plus the minimum context needed to read
  them. Do not paste the whole function.
- The terminal colours `-` lines red and `+` lines green. Colouring is per
  line, so keep one finding to one change — do not merge two unrelated edits
  into one block.
- For a deleted comment, write only `-` lines.
- For a rename, show the declaration line only. The `scope` field carries the
  other references; never list them as diff lines.

After the last finding, list what you reviewed and deliberately did not report,
and why — one line per class (e.g. "section banners", "library module aliases",
"domain vocabulary: bufnr, lnum"). This proves the coverage was aggressive and
the edits selective.

End with: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 6. Apply selected

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
- For renames, update every reference in scope. Then search the whole scope for
  the old name and confirm zero hits remain.
- Change only the lines a finding names. Do not reformat, re-indent, or
  re-wrap anything else.
- Keep the file's existing conventions: line endings, indent character, and
  final newline. Read the file's current state before you write it back.

## 7. Verify

- After applying, run the project's formatter and linter if it has them
  (check the repo config for the tool it uses), and confirm every changed file
  still parses, compiles, or passes its tests. Report the command and its
  result.
- If a check fails, fix it or revert that finding. Never report the work as
  done with a failing check.

