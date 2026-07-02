---
name: plan
description: >
  High-level phased planning for a subject. Brutally critiques the idea,
  refines through Q&A, then saves a self-contained, updatable plan to
  plans/<slug>.md at git root for fresh-context handoff. Never writes
  code or commits. Use when user invokes "/plan <subject>".
argument-hint: "<subject>"
---

# Plan

Plan the subject that follows. Output a phased, commitable plan saved as a single markdown file.

## Hard rules

1. **No code, no commits, no edits to anything but the plan file.** This skill plans only.
2. **Two approval gates: slug and save.** Confirm the slug before creating the file (rule 3), and do not save until you have said the exact phrase **"Plan is ready to save."** and the user approves. Do not write code from this plan — phase detail is a separate, fresh-context invocation.
3. **Save location.** `<git-root>/plans/<slug>.md`. Create `plans/` if missing. Resolve git root with `git rev-parse --show-toplevel`. Slug from subject (kebab-case); propose and confirm before writing.
4. **File is canonical after save.** Once saved, the file is the plan. Do not silently restate or revise plan content in conversation — either write the change to the file or stop. Otherwise the in-memory and on-disk plans diverge and fresh context inherits the stale one.

## Flow

### 1. Brutal critique

First, ground the critique in code. If the subject touches files or systems you have not read, explore them before attacking — read the relevant code, grep for usage, or spawn an Explore agent for breadth. Generic critiques from assumption are the failure mode; do not produce them.

Then attack the idea on these axes:
- **Scope creep** — what is bundled in that does not need to be?
- **Hidden complexity** — what looks small but is not?
- **Rejected alternatives** — what other approaches exist; why is this one right?
- **Sequencing risk** — what must be true for the plan to work, and is it?
- **Load-bearing assumptions** — what single thing being wrong would invalidate the plan?

Be direct. No hedging. Then ask the clarifying questions that fall out of the critique.

### 2. Refine

Loop: user answers → integrate → surface what is still unresolved → ask again. Keep the plan structure visible (subject, goal, constraints, phases) so the user sees it taking shape. Stop when nothing remains to refine, then say verbatim: **"Plan is ready to save."** Wait for explicit approval before writing the file.

### 3. Save

On approval, write `<git-root>/plans/<slug>.md` using the template below. Self-contained: a fresh Claude with no memory of this conversation must be able to pick it up.

````markdown
# <Subject>

_Last updated: YYYY-MM-DD — commit `<sha>`_

## Goal
One paragraph. What "done" looks like.

## Constraints / non-goals
Bulleted. What is explicitly out of scope.

## Key decisions (pre-implementation)
For each: decision, why, what was rejected and why.

## Repo context a fresh Claude needs
Quirks, conventions, file paths, prior incidents, anything not derivable from a quick `ls` or `git log`.

## Phases

### [ ] Phase 1: <name>
- **Goal:** ...
- **Scope:** ...
- **Done when:** ... (mergeable check — repo is not broken at end of phase)
- **Risk:** low | medium | high
- **Depends on:** none | phase N

(repeat per phase; single phase is fine if the work is small)

## Decisions log (during implementation)
Append-only. Each entry: `YYYY-MM-DD — decision — why`. Future sessions add to this as choices are made.

## Open questions
Deferred items. Empty if none.

## Hand-off
To detail a phase, start a fresh context and ask:
> Prepare a detailed plan for phase N from `plans/<slug>.md`.

**Before writing phase detail, verify the plan is not stale.** Compare the **Last updated** commit to current `HEAD`; read the files cited in **Repo context** to confirm they still exist and behave as described. If anything has drifted, surface the drift and update the plan before producing detail.
````

### 4. Updating the plan after a phase

When a phase changes state, update its heading in place:
- Pending: `### [ ] Phase 1: <name>`
- Done: `### [x] Phase 1: <name> — <commit-sha-or-range>` (use a range or PR ref if it spans several commits)
- Blocked: `### [!] Phase 1: <name>` — add a Decisions log entry explaining the block
- Abandoned: `### [~] Phase 1: <name>` — add a Decisions log entry explaining why

Bump the **Last updated** line at the top of the file on every change (date + current `HEAD` sha). Decisions made during a phase go in the **Decisions log**, not the pre-implementation section.

## Phasing rules

1. **Single phase if small.** If the work fits one logical PR with one concern, do not manufacture phases.
2. **Risk-last by default.** Low-risk wins early so they ship even if later phases stall.
3. **Forced ordering wins.** If a high-risk foundational change must go first (cannot build on a broken abstraction), put it first and note why in that phase.
4. **Each phase mergeable on its own.** No phase leaves the repo in a broken state.
5. **Logical or risk grouping.** A phase can span many file changes if they share one concern. Granularity is coarse, not fine.
