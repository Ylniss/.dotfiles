---
name: plan-review
description: >
  Adversarial review of a saved plan in plans/<slug>.md: verifies claims
  against the repo, finds gaps, proposes alternatives. Use when user invokes
  "/plan-review [plan]".
argument-hint: "[plan]"
---

# Plan review

Review a plan written by the plan skill, before /phase spends work on it.
Report-only until the user picks; then edit the plan file.

Best run in a fresh context — after `/clear` or a compact. The session that
wrote the plan tends to approve its own plan. This is advice, not a gate.

## Hard rules

1. **No code.** This skill edits the plan file and nothing else.
2. **Evidence or drop.** Every claim finding cites what the repo returned.
   Never assert from memory.
3. **Woven, not appended.** An applied finding is written as if the plan had
   been authored with it from the start.
4. **One approval gate.** Report, then apply only the findings the user names.

## 1. Pick the plan

- **Argument given** — resolve it as a slug or path under `<git-root>/plans/`.
  If it does not resolve, fall through to the list below.
- **No argument** — list every plan in `<git-root>/plans/`, numbered, each with
  last-updated date, reviewed date, and phase count (done/total). Ask which
  one. Never assume the newest.
- No `plans/` directory, or it is empty — say so and stop.

Read the whole plan file before anything else.

## 2. Drift check

Compare the plan's **Last updated** commit to current `HEAD`. Read the files
named in **Repo context** and confirm they still exist and behave as the plan
describes.

Drift is a finding like any other (category `claim`), reported with the rest.
Do not fix it silently and do not bury it in a preamble.

## 3. Verify claims (REQUIRED)

Check every statement the repo can confirm or refute. Read and grep — memory
is not evidence.

At minimum:

- file and directory paths
- symbol names — functions, types, commands, config keys, env vars
- counts and quantities — "12 call sites", "three places", "only used here"
- versions, from the lockfile or manifest
- "X already exists" and "Y does not exist yet"
- claims about how existing code behaves

A claim finding without an `evidence:` line is not reportable — drop it.
Claims the repo cannot settle (external services, future work, taste) are out
of scope for this step; they may still be a `gap`.

## 4. Find gaps

Soft requirement, aimed at what the plan actually touches. Read the code the
plan will change first, then ask what the plan does not say. Spawn an Explore
agent when the subject spans more than you can read directly.

Starting points, not a closed set:

- a phase with no "Done when", or one that cannot be checked
- a phase that leaves the repo broken on its own
- `Depends on` order that does not match how the code really depends
- no rollback, migration, or data path where the change needs one
- a load-bearing assumption the plan never states
- work the plan implies but assigns to no phase

A gap found by reading code beats a gap found by reading the plan.

## 5. Alternatives (capped at two)

Only when a different approach would materially change the plan — a different
shape, not a variation. Two is the ceiling; zero is a normal result.

Every alternative must name what the current plan does better. An alternative
with no stated trade-off is not analysis — drop it.

Do not re-run the critique the plan skill already did before the plan was
saved. Raise only what the written plan makes visible.

## 6. Filter and rank

- Drop nitpicks. Only report what is worth changing in the plan.
- Rank by impact: what would waste the most work first.
- Set a confidence for every finding: H, M, or L. For `claim`, H means the
  evidence settles it.
- Set a recommend flag. `✓` when you would make the change yourself — the win
  is real and the risk to the plan is low. `✗` for taste, for a deliberate
  choice the plan already justifies, or for anything resting on an assumption
  you could not verify.
- If nothing is worth changing, say so, stamp the review (step 9), and stop.
  Do not invent a finding to have something to report.

## 7. Report (do not edit yet)

Numbered list so the user can pick:

    N. [category][H|M|L][✓|✗] <plan section or phase> — short title
       why:      <one line>
       evidence: <what the repo returned — claim findings only>
       fix:      <what changes in the plan, one line>

Header tag rules — three tags, no spaces between them, always in this order:

1. Category: `claim`, `gap`, `sequencing`, `scope`, or `alternative`.
2. Confidence: a single letter — `H`, `M`, or `L`.
3. Recommend flag: `✓` if you recommend applying it, `✗` if you do not.

Never write "(confidence: high)" at the end of the line — the tags carry it.

Point at the plan's own section or phase name, not a line number — applying
rewrites the file.

The `evidence:` line is required for every `claim` finding and names what was
read or grepped, and what came back. Omit it for the other categories.

No diff blocks. Plan prose reads badly as a diff; the `fix:` line carries the
change.

End with: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 8. Apply — weave, never append

Apply only the findings the user names. "recommended" means every finding
tagged `✓`, and nothing tagged `✗`.

The plan must come out reading as though it had been written this way from the
start:

- A corrected claim is rewritten in its own sentence, in place.
- A new phase is inserted at its right position, renumbered, with every
  `Depends on` reference and the top-of-file **Phases** list updated to match.
- Removed scope disappears from the Scope line. It is not struck through, not
  parenthesised, not marked "dropped".
- No trace of the review in the plan body: no "(fixed in review)", no "Review
  findings" section, no dated annotation for a correction.
- Exception: an alternative the user rejected belongs in **Key decisions** as a
  rejected option with its reason. That section exists for exactly this.
- The **Decisions log** is append-only and belongs to implementation. Review
  outcomes never go there.
- Leave every untouched section byte-identical. Do not rewrap, re-indent, or
  restyle prose no finding named.

## 9. Stamp the review

Always, even when nothing was found and nothing was applied:

- Set `_Reviewed: YYYY-MM-DD — commit <sha>_` directly under the Last updated
  line, using today's date and current `HEAD`. Insert it if the plan predates
  this convention.
- Bump `_Last updated:_` only if the file content changed.

Then report: which findings were applied, which were skipped, and what the
plan file now says. No commit — the plan skill's rules stand.
