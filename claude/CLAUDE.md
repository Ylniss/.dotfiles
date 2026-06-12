# Global Rules

## Approval

- Never write or modify code without my approval.
- Never `git commit` without my explicit say-so.

## Code Style

- No dead code — don't add params, fields, or logic nothing currently uses.
- Keep TODO comments unless implementing what they describe.
- Prefer early return over nested ifs. Invert conditions and return/continue early.
- Fail fast — no defensive null checks for values that can't be null. If they are null, it's a bug; let it throw early.

## Communication

- Be brutally honest. Say plainly if an approach is bad, overcomplicated, or wrong.
- Planning: high-level steps first (WHAT/WHY, not HOW). No file paths or code. Wait for approval before details.

## Git

- "commit" = stage all, short one-line message, commit.
