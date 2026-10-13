def --wrapped claude [...args] {
  ^claude --settings $'($nu.home-dir)/.claude/dotfiles.settings.json' ...$args
}

# Second account: its own login lives in a separate config dir.
def --wrapped claude2 [...args] {
  with-env { CLAUDE_CONFIG_DIR: $'($nu.home-dir)/.claude-2' } { claude ...$args }
}
