def --wrapped claude [...args] {
  ^claude --settings $'($nu.home-dir)/.claude/dotfiles.settings.json' ...$args
}
