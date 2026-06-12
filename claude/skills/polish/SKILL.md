---
name: polish
description: >
  Review the current git changes for simplification, optimization, and
  modern-library usage. Reports findings first, applies only the ones the
  user picks. Use when the user says "polish", "polish changes", "review
  my changes", or asks what in the diff could be simplified/improved/
  optimized or made to use current library patterns.
---

# Polish

Report-only review of the current diff for quality and modernization, then
apply the findings the user selects. This does NOT hunt for bugs (use
/code-review for that) and does NOT auto-apply (unlike /simplify).

## 1. Get the changes

- Default scope: `git diff HEAD` (staged + unstaged tracked changes).
- Also include new untracked files: `git ls-files --others --exclude-standard`.
- If the user passed an argument, diff against it instead: `git diff <arg>`
  (e.g. `main`, `HEAD~3`, a branch). The arg is a git ref or range.
- If there are no changes, say so and stop.

## 2. Look up modern patterns via context7 (REQUIRED)

context7 is mandatory whenever the diff touches an external library or
framework. Never judge "modern usage" from memory — training data lags real
APIs. Do not skip this even if you think you know the answer.

- List every external library/framework in the changed lines (imports/`using`/
  `require`), with its version from the lockfile/manifest (package.json,
  *.csproj, Cargo.toml, go.mod, etc.).
- For each, invoke the `context7-mcp` skill to fetch current docs (it handles
  resolve-library-id → version-specific select → query-docs).
- Hard rule: every "modern-pattern" finding MUST cite what context7 returned.
  If context7 has no docs or doesn't support the suggestion, drop the finding —
  do not assert it from memory.
- Verify the suggested API exists in the installed version before reporting it.
  No hallucinated "just use X."
- Only exception: if the diff touches no external library, there is nothing to
  query — say so and skip. The simplify/optimize checks still run.

## 3. Build findings

Look for, in priority order:
1. Real simplification — collapse needless complexity, remove redundancy,
   dedupe repeated logic.
2. Optimization — only when it measurably matters; note the cost being saved.
3. Modern-library patterns — replace dated usage with the current idiom the
   library now recommends (backed by context7).

Apply the user's own style rules as review criteria:
- Early return over nested ifs — invert conditions, return/continue early.
- Fail fast — flag defensive null checks for values that can't be null.
- No dead code — flag params/fields/logic nothing uses.
- Keep TODO comments unless the change implements what they describe.

## 4. Filter and rank

- Drop trivial nitpicks. Only report what is worth a change.
- Rank by impact: clear wins first, subjective/optional polish last.
- Mark confidence on anything you're unsure about.

## 5. Report (do not code yet)

Numbered list so the user can pick. Per finding:

```
N. [category] file:line — short title  (confidence: high/med/low)
   current:  <tight snippet or description>
   proposed: <tight snippet or description>
   why:      <one line>
```

End with: "Which to apply? (e.g. 1,3,5 / all / none)"

## 6. Apply selected

- Apply only the findings the user names.
- Make exactly the proposed change, nothing extra.
