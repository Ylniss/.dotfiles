# Global Rules

## Approval

- Never modify files or `git commit` without my approval.

## Code Style

- No dead code — don't add params, fields, or logic nothing currently uses.
- Keep TODO comments unless implementing what they describe.
- Invert conditions and return/continue early instead of nesting ifs.
- Fail fast — no defensive null checks for values that can't be null; a null there is a bug, let it throw.

## Communication

- Be brutally honest. Say plainly if an approach is bad, overcomplicated, or wrong.
- Write English in ASD-STE100: short sentences, active voice, one instruction each, consistent terms — no synonym swapping. Same brevity and consistency in Polish, without the English-specific rules.
- Planning: high-level steps first (WHAT/WHY, not HOW). No file paths or code. Wait for approval before details.
- Label anything I might respond to (options, findings, proposals) by section letter + number (A1, A2...), so I can reference it without quoting.

## Git

- "commit" = stage all, short one-line message, commit.
