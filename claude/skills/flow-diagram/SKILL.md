---
name: flow-diagram
description: >
  Draws one SVG of simplified UML sequence diagrams that explain how a feature
  works end to end (client → API → modules → storage), at the level you would
  use to walk a colleague through it, not every method. The target is a plan
  file, a branch (diffed against develop), or a free-text description of a
  mechanism. Use when the user invokes "/flow-diagram <target>" or asks for
  flow or sequence diagrams of a plan, a branch, or how something works.
argument-hint: "<plans/x.md | branch | description of a mechanism>"
---

# Flow diagram

Produce one SVG page that explains how the target works. The reader knows the codebase but not this feature.

You write the content as a JSON spec. `scripts/render.py` lays it out, so never write SVG by hand. Read `references/spec-format.md` before writing the spec. `references/example.json` is a complete real spec (service offer images, 12 sections) to match for level of detail. Run the scripts with `py` on Windows and `python3` elsewhere. They need only the standard library.

## 1. Resolve the target

From the argument:

- **Empty** — ask what to draw and stop.
- **An existing `.md` file** — a **plan**. A `.md` path that does not exist: say so and stop.
- **`git rev-parse --verify --quiet <arg>` succeeds** — a **branch**. The base is the first of `origin/develop`, `develop`, or the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`). Scope: `git log --no-merges <base>..<arg>` and `git diff <base>...<arg>`. The three dots exclude what the branch merged in from the base. State the base in one line before you start.
- **Anything else** — a **topic**: a description of a mechanism to find in the code.

The output goes to `plans/<slug>-flows.svg`:

- plan: the plan's file name without `.md`
- branch: the branch name, with `/` replaced by `-`
- topic: a short kebab-case English slug of the description

If the repo has no `plans/` directory, ask where to write. If the file exists, it is an earlier run: overwrite it and say so.

## 2. Gather what actually happens

Draw from code. A plan says what was intended; the code says what happens.

- **Plan** — read the whole plan and every document it builds on (e.g. a solution file it names as the spec). Find the implementation: the commits, branch, or types the plan names. Draw the implemented parts from the code. Draw unimplemented parts from the plan and say so in that section's subtitle ("wg planu, jeszcze niezaimplementowane").
- **Branch** — read the commit messages and `git diff --stat` first. Then read every entry point the diff adds or changes:
  - endpoints with their version
  - command and query handlers
  - module requests and their subscriptions
  - event handlers
  - background jobs
  - schema changes that alter behaviour
- **Topic** — find the entry points with Grep and Glob, then follow the calls across modules.
- **Client side** — the repo's AGENTS.md or CLAUDE.md, or the plan, may name sibling front-end repos. If such a repo exists on disk, read its side of the flow there. Otherwise draw the client from the plan and mark it as such.
- **Large scope** — more than ~4 modules or ~60 changed files. Run Explore agents in parallel, one per module or area. Ask each for:
  - its entry points (route + version)
  - the flow steps
  - cross-module calls and events
  - commit points
  - failure branches
  - a `file:line` for every claim

  Read the code yourself for anything surprising before you draw it.

Every step you draw must trace to code or plan text you read. Never invent field, route, or event names.

## 3. Build the case map

List every entry point in scope: an endpoint (method, route, version), a module request, an event handler, or a job. For each one, record:

- who calls it
- which field carries the relevant data
- which mechanism or variant handles it
- which diagram shows it

This list becomes the case-map table and the checklist for step 6.

## 4. Design the page

Layout, top to bottom:

1. **Header** — the title, an `intro` paragraph (scope, what comes from code and what from the plan, abstraction level), and the legend.
2. **`0 · Idea w N krokach`** (a `steps` section) and **the case map** (a `table`). Include both only when there are 3 or more cases. A small mechanism goes straight to its diagram.
3. **Numbered `sequence` sections**, one per distinct mechanism or variant. When several flows share steps (common validation, a shared upload), draw those steps once and refer to them from the others ("→ diagram 2").
4. **`table` sections** for matrices: analytics events, permissions, version differences.

Each sequence diagram:

- **Participants (3–6)** — actors, apps, modules, storage, databases, and an "after commit: events" participant. Use a class only when it is the mechanism itself.
- **Show** what a colleague needs to predict behaviour:
  - limits and validation
  - commit and transaction boundaries
  - what runs after the commit
  - failure branches that change the outcome (`alt` / `opt` frames)
  - backwards compatibility
- **Skip** mapping, DI, logging, getters, and trivial guards.
- **Keep to about 15 numbered steps.** Split a longer diagram.

Write the prose in the language the user writes to you. Identifiers, routes, types, and events stay in English inside `` `code` ``.

## 5. Render and inspect

1. Write the spec to the scratchpad.
2. `scripts/render.py <spec.json> plans/<slug>-flows.svg`. A `spec error:` line names the bad element. Fix it and rerun.
3. `scripts/preview.py plans/<slug>-flows.svg <scratchpad>/preview` writes 1300 px PNG segments using headless Chrome or Edge. Read every PNG and fix what you see; "Fixing what the preview shows" in `spec-format.md` maps each symptom to its cause. Re-render and look again until it is clean.

If `preview.py` exits with code 2, no browser was found. Skip the visual check and tell the user.

## 6. Completeness check (plan and branch targets)

Run one general-purpose agent. Give it:

- the target (plan path, or `<base>...<branch>`)
- the spec path
- the case map

Ask it to report two things, each with `file:line`:

- **(a)** entry points or behaviours in scope that no diagram shows
- **(b)** steps in the diagrams that contradict the code or the plan

Verify each finding yourself. Fix the confirmed ones, then render and preview again.

## 7. Report

Reply with:

- the output path
- one line per section
- which parts come from the plan rather than the code
- the step 6 findings: what you fixed, and what you rejected and why

Do not paste the spec.
