# Shared helpers for the scripts in this directory.

export def is-windows [] { $nu.os-info.family == 'windows' }
export def is-android [] { $nu.os-info.name == 'android' }
export def is-linux   [] { $nu.os-info.name == 'linux' }

# Returns the dotfiles repo directory for this platform
export def dotfiles-repo-dir [] {
  let home = if (is-windows) { $env.USERPROFILE } else { $env.HOME }
  $'($home)/stuff/repo/.dotfiles'
}
