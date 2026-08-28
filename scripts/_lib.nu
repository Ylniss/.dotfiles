# Shared helpers for the scripts in this directory.

export def is-windows [] { $nu.os-info.family == 'windows' }
export def is-android [] { $nu.os-info.name == 'android' }
export def is-linux   [] { $nu.os-info.name == 'linux' }

# Returns the dotfiles repo directory for this platform
export def dotfiles-repo-dir [] {
  let home = if (is-windows) { $env.USERPROFILE } else { $env.HOME }
  $'($home)/stuff/repo/.dotfiles'
}

export def warn [msg: string] {
  print -e $"(ansi yellow)($msg)(ansi reset)"
}

# Returns the profile directory the installed LibreWolf opens, or null
export def librewolf-profile-dir [] {
  let root = if (is-windows) { $'($env.APPDATA)/librewolf' } else { $'($env.HOME)/.librewolf' }
  let ini = $'($root)/profiles.ini'
  if not ($ini | path exists) { return null }

  # The [InstallXXX] section names the profile the browser opens. Its Default
  # holds a path, unlike the plain `Default=1` flag in [ProfileN].
  let paths = (open $ini | lines | parse --regex '^Default=(?<rel>.*/.*)' | get rel)
  if ($paths | is-empty) { return null }
  let dir = $'($root)/($paths | first)'
  if ($dir | path exists) { $dir } else { null }
}
