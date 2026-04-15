# Nushell Config

Personal nushell (v0.111+) dotfiles. No build/test/lint — validate by loading in a live nushell session.

## Architecture

- **`env.nu`** — Env vars, PATH, SSH agent init, Starship prompt cache. Runs first on startup.
- **`config.nu`** — Theme, then `$env.config` (only non-default values). Sources all `scripts/` at the end. Starship loaded via `use ~/.cache/starship/init.nu`.
- **`scripts/`** — Domain-specific modules, sourced via `source <name>.nu` in config.nu. Resolved through `$env.NU_LIB_DIRS` (set in env.nu → `scripts/`).

## Conventions

- **Cross-platform**: Must handle Windows, Linux, Android. Use `$nu.os-info.family` / `$nu.os-info.name` for OS branching.
- **Wrapped commands**: CLI wrappers use `def --wrapped` for variadic passthrough.
- **Environment-mutating functions**: `def --env` when changing `cd` or setting env vars.
- **Naming**: Multi-word subcommands (`docker stop all`, `ssh mob cp`) over abbreviations. Short aliases only for high-frequency navigation (`vi`, `repo`, `dwn`).
- **External tools assumed present**: starship, fzf, fd, ripgrep, neovim, git, gh, docker, yazi, wezterm, ssh-agent. No fallback logic.
- **Minimal config**: Only non-default `$env.config` values. Check defaults with `config nu --default` or `$env.config.<field>`.
