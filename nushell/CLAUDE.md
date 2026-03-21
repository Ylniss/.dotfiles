# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal nushell (v0.111+) configuration dotfiles. No build/test/lint tooling — changes are validated by loading them in a live nushell session.

## Architecture

- **`env.nu`** — Environment variables, PATH setup, SSH agent init, Starship prompt cache. Runs first on shell startup.
- **`config.nu`** — Theme, then `$env.config` with only non-default values (nushell applies defaults for anything omitted). Sources all scripts from `scripts/` at the end. Starship loaded via `use ~/.cache/starship/init.nu`.
- **`scripts/`** — Domain-specific modules, each sourced via `source <name>.nu` in config.nu. Scripts are resolved through `$env.NU_LIB_DIRS` (set in env.nu to point to `scripts/`).

## Conventions

- **Cross-platform**: Code must handle Windows, Linux, and Android. Use `$nu.os-info.family` / `$nu.os-info.name` for OS-conditional logic.
- **Wrapped commands**: Git and other CLI wrappers use `def --wrapped` for variadic passthrough to the underlying binary.
- **Environment-mutating functions**: Use `def --env` when the function changes `cd` or sets env vars.
- **Naming**: Multi-word subcommands (`docker stop all`, `ssh mob cp`) over abbreviation soup. Short aliases reserved for high-frequency navigation (`vi`, `repo`, `dwn`).
- **External tools assumed present**: starship, fzf, ripgrep, neovim, git, docker, lf. Don't add fallback/detection logic — if a tool is missing, the error is obvious.
- **Minimal config**: Only specify non-default `$env.config` values. Don't restate nushell defaults — check with `config nu --default` or inspect `$env.config.<field>`. Only custom keybindings belong in config; nushell has ~130 built-in keybindings.
