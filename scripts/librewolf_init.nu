#!/usr/bin/env nu

# Sets up the parts of LibreWolf that the symlink table in install_dotfiles.nu
# cannot cover.

use _lib.nu *

def main [] { init-librewolf (dotfiles-repo-dir) }

export def init-librewolf [repo_dir] {
  link-librewolf-overrides $repo_dir
  link-librewolf-userchrome $repo_dir
  apply-librewolf-cookie-exceptions $repo_dir
  install-librewolf-extensions $repo_dir
}

# Links librewolf.overrides.cfg to where the installed LibreWolf reads it
def link-librewolf-overrides [repo_dir] {
  let overrides_file = (librewolf-overrides-file)
  if $overrides_file == null {
    warn 'LibreWolf profile not found. Start LibreWolf once, then rerun. Skipping librewolf.overrides.cfg.'
    return
  }
  create-symbolic-link $'($repo_dir)/librewolf/librewolf.overrides.cfg' $overrides_file 'librewolf.overrides.cfg'
}

# Links userChrome.css into the LibreWolf profile, whose directory name is random
def link-librewolf-userchrome [repo_dir] {
  let profile_dir = (librewolf-profile-dir)
  if $profile_dir == null {
    warn 'LibreWolf profile not found. Skipping userChrome.css.'
    return
  }
  create-symbolic-link $'($repo_dir)/librewolf/userChrome.css' $'($profile_dir)/chrome/userChrome.css' 'librewolf userChrome.css'
}

# LibreWolf clears cookies and site data on shutdown. Only a
# `persist-data-on-shutdown` ALLOW permission survives it, the one the
# "Manage Exceptions…" dialog writes; a `cookie` ALLOW permission does nothing.
# Those permissions live in the profile database, which cannot be symlinked, so
# this script writes them from librewolf/cookie-allow.txt instead.
def apply-librewolf-cookie-exceptions [repo_dir] {
  let origins = (read-list $'($repo_dir)/librewolf/cookie-allow.txt')

  let profile_dir = (librewolf-profile-dir)
  if $profile_dir == null {
    warn 'LibreWolf profile not found. Skipping cookie exceptions.'
    return
  }

  let db = $'($profile_dir)/permissions.sqlite'
  if not ($db | path exists) {
    warn $'($db) not found. Start LibreWolf once, then rerun. Skipping cookie exceptions.'
    return
  }

  if (ps | where name =~ '(?i)librewolf' | is-not-empty) {
    warn 'LibreWolf is running and would overwrite the changes at exit. Close it, then rerun. Skipping cookie exceptions.'
    return
  }

  let now_ms = ((date now | into int) // 1_000_000)
  let conn = (open $db)
  $conn | query db "delete from moz_perms where type = 'persist-data-on-shutdown'"
  for origin in $origins {
    $conn | query db "insert into moz_perms (origin, type, permission, expireType, expireTime, modificationTime) values (?, 'persist-data-on-shutdown', 1, 0, 0, ?)" -p [$origin, $now_ms]
  }
  print $'(ansi green)Applied(ansi reset) ($origins | length) LibreWolf cookie exceptions'
}

# Adds the extensions from librewolf/extensions.txt to the ExtensionSettings
# policy of the installed LibreWolf, which then installs them at the next start.
# Every other policy stays as LibreWolf ships it.
def install-librewolf-extensions [repo_dir] {
  let wanted = (read-list $'($repo_dir)/librewolf/extensions.txt'
    | parse --regex '^(?<id>\S+)\s+(?<slug>\S+)$'
    | reduce --fold {} { |e, acc| $acc | merge { ($e.id): {
        install_url: $'https://addons.mozilla.org/firefox/downloads/latest/($e.slug)/latest.xpi'
        installation_mode: 'normal_installed'
      } } })

  let policies_file = (librewolf-policies-file)
  if $policies_file == null {
    warn 'LibreWolf installation not found. Skipping extensions.'
    return
  }

  let config = (open $policies_file)
  let current = ($config.policies.ExtensionSettings? | default {})
  let merged = ($current | merge $wanted)
  if $merged == $current {
    print $'(ansi blue)LibreWolf extensions already in the policies file.(ansi reset)'
    return
  }

  # The policies file sits in the installation directory, so the copy needs
  # administrator rights. Only the copy is elevated, never this script.
  let new_policies_file = (mktemp --suffix '.json')
  $config | upsert policies.ExtensionSettings $merged | to json --indent 4 | save -f $new_policies_file
  copy-file-elevated $new_policies_file $policies_file
  rm -f $new_policies_file

  let applied = ((open $policies_file).policies.ExtensionSettings? | default {})
  if $applied != $merged {
    warn $'Could not write ($policies_file). Rerun with administrator rights. Skipping extensions.'
    return
  }
  print $'(ansi green)Applied(ansi reset) ($wanted | columns | length) LibreWolf extensions. Restart LibreWolf to install them.'
}

# Returns the lines of a tracked list file, without blanks and comments
def read-list [file] {
  open $file
    | lines
    | str trim
    | where { |l| ($l | is-not-empty) and (not ($l | str starts-with '#')) }
}

# Returns the policies file of the installed LibreWolf, or null
def librewolf-policies-file [] {
  let candidates = if (is-windows) {
    [$'($env.ProgramFiles)/LibreWolf/distribution/policies.json'
     $'($env.LOCALAPPDATA)/LibreWolf/distribution/policies.json']
  } else {
    ['/usr/share/librewolf/distribution/policies.json'
     '/usr/lib/librewolf/distribution/policies.json'
     '/opt/librewolf/distribution/policies.json']
  }
  $candidates | where { |c| $c | path exists } | path expand | get -o 0
}

# Copies a file, asking for administrator rights when the process lacks them
def copy-file-elevated [src, dest] {
  if (is-elevated) {
    cp $src $dest
    return
  }

  print $'Asking for administrator rights to write ($dest)'
  if not (is-windows) {
    do --ignore-errors { ^sudo cp $src $dest }
    return
  }

  # Start-Process takes its arguments as a list, which cannot hold a path with
  # spaces as one item, so the paths go into a script file it runs instead.
  let win_src = ($src | str replace --all '/' '\')
  let win_dest = ($dest | str replace --all '/' '\')
  let copy_script = (mktemp --suffix '.ps1')
  $"Copy-Item -LiteralPath '($win_src)' -Destination '($win_dest)' -Force\n" | save -f $copy_script
  do --ignore-errors {
    ^powershell -NoProfile -Command $"Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','($copy_script)'"
  }
  rm -f $copy_script
}
