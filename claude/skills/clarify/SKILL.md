---
name: clarify
description: >
  Review the current git changes for comment essence and name directness.
  Reports findings first, applies only the ones the user picks. Use when the
  user says "clarify", "clarify changes", "fix names and comments", or asks
  to tighten comments / improve naming in the diff.
argument-hint: "[base ref]"
---

# Clarify

Report-only review of the current diff for clear comments and direct names,
then apply the findings the user selects. Quality only — no logic changes.

## 1. Get the changes

- Default scope: `git diff HEAD` (staged + unstaged tracked changes).
- Also include new untracked files: `git ls-files --others --exclude-standard`.
- If the user passed an argument, diff against it instead: `git diff <arg>`
  (e.g. `main`, `HEAD~3`, a branch). The arg is a git ref or range.
- If there are no changes, say so and stop.

## 2. Review comments

Goal: every comment is essence only — simple words, direct, no fluff, no
mental leap to understand it.

Evaluate EVERY comment in the diff — do not sample or cherry-pick. Each comment
gets one of these verdicts: keep as-is / shorten / reword / delete. Report all
that need a change; only edit those. Aggressive coverage, selective edits — a
comment that is already fine stays untouched.

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

Flag a name when it is:
- Vague — too short or generic to convey meaning (`d`, `tmp`, `data`, `mgr`).
- Misleading — implies the wrong thing (highest priority; worse than vague).
- Over-verbose — longer than needed without adding clarity.

Constraints:
- Match the naming conventions already used in the surrounding code.
- For every rename, note the blast radius: how many references it touches and
  whether it crosses a file or public/exported boundary (safe vs risky).
- If a rename makes a nearby comment redundant, note that too.

## 4. Report (do not code yet)

Numbered list so the user can pick. Per finding:

```
N. [comment|name] file:line — short title
   current:  <name or comment>
   proposed: <new name or comment, or DELETE>
   why:      <one line>
   scope:    <only for renames: ref count + safe/risky>
```

End with: "Which to apply? (e.g. 1,3,5 / all / none)"

## 5. Apply selected

- Apply only the findings the user names.
- For renames, update every reference in scope.
