# Nushell Config

Personal nushell (v0.114+) dotfiles. No build/test/lint — validate by loading in a live nushell session.

## Architecture

- **`env.nu`** — Env vars, PATH, SSH agent init, Starship prompt cache. Runs first on startup.
- **`config.nu`** — Theme, then `$env.config`. Sources all `scripts/` at the end. Starship loaded via `use ~/.cache/starship/init.nu`.
- **`scripts/`** — Domain-specific modules, sourced via `source <name>.nu` in config.nu. Resolved through `$env.NU_LIB_DIRS` (set in env.nu → `scripts/`).

## Conventions

- **Cross-platform** (Windows, Linux, Android): branch with the `is-windows` / `is-android` / `is-macos` helpers from `env.nu`, never raw `$nu.os-info.*`.
- **Wrapped commands**: CLI wrappers use `def --wrapped` for variadic passthrough.
- **Environment-mutating functions**: `def --env` when changing `cd` or setting env vars.
- **Naming**: commands/sub-commands/flags in `kebab-case`, variables/parameters in `snake_case`, env vars in `SCREAMING_SNAKE_CASE`. Multi-word subcommands (`docker stop all`, `ssh mob cp`) over abbreviations. Short aliases only for high-frequency navigation (`vi`, `repo`, `dwn`).
- **External tools**: assume installed. No fallback logic, no availability checks.
- **Minimal config**: Only non-default `$env.config` values. Check defaults with `config nu --default` or `$env.config.<field>`.
