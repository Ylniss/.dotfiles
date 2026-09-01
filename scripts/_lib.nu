# Shared helpers for the scripts in this directory.

export def is-windows [] { $nu.os-info.family == 'windows' }
export def is-android [] { $nu.os-info.name == 'android' }
export def is-linux   [] { $nu.os-info.name == 'linux' }

# True if the process runs as Administrator (Windows) or root
export def is-elevated [] {
  if (is-windows) {
    (^powershell -NoProfile -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" | str trim) == 'True'
  } else {
    (^id -u | str trim) == '0'
  }
}

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

# Reads where a symlink points (lists parent so directory symlinks aren't followed into)
def read-symlink-target [link_path] {
  let parent = ($link_path | path dirname)
  let basename = ($link_path | path basename)
  let matches = try {
    ls --long $parent | where { |r| ($r.name | path basename) == $basename }
  } catch { [] }
  if ($matches | is-empty) { '' } else { ($matches | first | get target? | default '') }
}

# True if two paths point to the same location (case/slash-insensitive on Windows)
def same-path [a: string, b: string] {
  if (is-windows) {
    ($a | str replace --all '\' '/' | str lowercase) == ($b | str replace --all '\' '/' | str lowercase)
  } else {
    $a == $b
  }
}

# Creates a symlink, replacing existing file/dir; on Windows clears stale ancestor reparse points first
export def create-symbolic-link [target, link_path, description] {
  # Remove any ancestor reparse point first so rm/mkdir below don't follow it
  # into its target.
  if (is-windows) {
    mut ancestor = ($link_path | path dirname)
    mut stale = ''
    loop {
      if ($ancestor | path exists -n) and (($ancestor | path type) == 'symlink') {
        $stale = $ancestor
        break
      }
      let up = ($ancestor | path dirname)
      if $up == $ancestor { break }
      $ancestor = $up
    }
    if ($stale | is-not-empty) {
      print $'Removing stale directory symlink before linking ($description): ($stale)'
      windows-delete-reparse $stale
    }
  }

  let is_symlink = ($link_path | path exists -n) and (($link_path | path type) == 'symlink')

  if $is_symlink {
    let current_target = (read-symlink-target $link_path)
    if (same-path $current_target $target) {
      print $'($description) (ansi blue)symbolic link already exists.(ansi reset)'
      return
    }
    print $'(ansi yellow)Updating(ansi reset) ($description) — was: ($current_target)'
    if (is-windows) {
      windows-delete-reparse $link_path
    } else {
      ^rm -f $link_path
    }
  }

  if ($link_path | path exists) {
    print $'Removing existing ($description) to replace with symbolic link'
    rm -rf $link_path
  }

  let parent_dir = ($link_path | path dirname)
  if not ($parent_dir | path exists) {
    mkdir $parent_dir
  }

  print $'(ansi green)Creating symbolic link for(ansi reset) ($description)'
  if (is-windows) {
    let win_target = ($target | str replace --all '/' '\')
    let win_link = ($link_path | str replace --all '/' '\')
    if ($target | path type) == 'dir' {
      ^cmd /c mklink /j $win_link $win_target
    } else {
      ^cmd /c mklink $win_link $win_target
    }
  } else {
    ^ln -s $target $link_path
  }
}

# Deletes a symlink or junction without touching its target
def windows-delete-reparse [path] {
  let del_script = '(Get-Item -Force -LiteralPath $env:DEL_PATH).Delete()'
  with-env { DEL_PATH: ($path | str replace --all '/' '\') } {
    ^powershell -NoProfile -Command $del_script
  }
}
