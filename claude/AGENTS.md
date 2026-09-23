# Global Rules

## Workflow

- Discuss the problem and get my approval before you change files or commit.
- Change files with Edit and Write. Use the shell only for bulk edits.

## Code Style

- No dead code — don't add params, fields, or logic nothing currently uses.
- Keep TODO comments unless implementing what they describe.
- Comment only a non-obvious WHY. No doc comment on a private member or on a type whose names already say it.
- Invert conditions and return/continue early instead of nesting ifs.
- Fail fast — no defensive null checks for values that can't be null; a null there is a bug, let it throw.

## Communication

- Be brutally honest. Say plainly if an approach is bad, overcomplicated, or wrong.
- Planning: high-level steps first (WHAT/WHY, not HOW). No file paths or code. Wait for approval before details.
- Label anything I might respond to (options, findings, proposals) by section letter + number (A1, A2...), so I can reference it without quoting.

## Git

- "commit" = stage all, short one-line message, commit.
