# Shared helpers for the scripts in this directory.

export def is-windows [] { $nu.os-info.family == 'windows' }
export def is-android [] { $nu.os-info.name == 'android' }
export def is-macos   [] { $nu.os-info.name == 'macos' }
export def is-linux   [] { $nu.os-info.name == 'linux' }

# Returns the dotfiles repo directory for this platform
export def dotfiles-repo-dir [] {
  let home = if (is-windows) { $env.USERPROFILE } else { $env.HOME }
  $'($home)/stuff/repo/.dotfiles'
}

# Returns the obsidian data directory for this platform
export def obsidian-data-dir [] {
  if (is-windows) {
    $'($env.APPDATA)/obsidian'
  } else if (is-macos) {
    $'($env.HOME)/Library/Application Support/obsidian'
  } else {
    $'($env.HOME)/.config/obsidian'
  }
}
