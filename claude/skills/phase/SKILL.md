---
name: phase
description: >
  Execute one phase of a saved plan from plans/<slug>.md, from outline gate
  to commit. Use when user invokes "/phase <plan> [N]".
argument-hint: "<plan> [N]"
---

# Phase

Execute a single phase from a plan produced by the plan skill. Two gates:
outline before code, review before commit.

## Hard rules

1. **One phase per invocation.** Scope is the phase's own Scope section —
   nothing else. Adjacent improvements go into the findings list or the
   plan's Open questions, not into the diff.
2. **Two approval gates.** No code before the user approves the outline.
   No commit before the user approves at the commit gate.
3. **The plan file is canonical.** Every state change (phase done/blocked,
   decisions made) is written to the plan file using the plan skill's
   update rules. Never let the file and reality diverge.
4. **Green gate.** Build clean and full test suite passing before the
   commit gate. Never commit red.

## Flow

### 1. Load and verify

- Resolve the plan: the arg is a slug or path under `<git-root>/plans/`.
  If it doesn't resolve, list available plans and stop.
- Pick the phase: explicit N if given, else the first `[ ]` phase.
  If none remain, say so and stop.
- Staleness check (mandated by the plan's Hand-off section): compare the
  plan's Last-updated commit to `HEAD`; read the files in Repo context and
  confirm they still exist and behave as described. On drift: report it,
  update the plan with the user, do not implement yet.
- Review check: read the plan's **Reviewed** line. If it says `never`, is
  missing, or its date is older than the **Last updated** date, the plan has
  changed since it was last reviewed. Say so and ask whether to run
  `/plan-review` first. The user may skip — do not block on it.
- Verify the phase's `Depends on` phases are `[x]`. If not, stop and say
  which are missing.

### 2. Outline gate

Produce a short implementation outline grounded in current code: approach,
files touched, order of changes, and how "Done when" will be verified.
No code yet. Ask for go — the user's go approves code for this phase's
scope only.

### 3. Implement

- Stay inside the phase Scope.
- Append choices made along the way to the plan's Decisions log
  (`YYYY-MM-DD — decision — why`).
- If the phase turns out unimplementable as planned: stop, report why,
  propose marking it `[!]` blocked with a Decisions-log entry, and wait.

### 4. Verify

- Run the project's build and full test suite (commands from project
  CLAUDE.md or the obvious project convention; ask if unclear).
- Check the phase's "Done when" criterion explicitly.
- Red → fix within scope. Can't fix within scope → stop and report;
  do not widen scope silently.

### 5. Self-review

Apply the clarify skill's review criteria (comment essence + name
directness) and the polish skill's criteria (simplification, optimization,
modern-library patterns — context7-backed) to the phase diff only — the
changes this phase made, not everything in `git diff HEAD`. Report-only:
skip those skills' own apply/ask steps and merge both reviews into one
numbered findings list.

### 6. Commit gate

Present together: diff summary (files + what changed per concern), test
result, findings list. Ask which findings to apply and whether to commit.

On approval:

- Apply only the selected findings; re-run tests if they changed code.
- Commit: one commit if the phase is a single concern, else split by
  concern. Short one-line messages.
- Update the plan: mark the phase `[x] — <sha or range>`, bump
  Last updated (date + `HEAD` sha), then commit the plan update
  separately.
- Report: phase done, commits made, next pending phase.
