#!/usr/bin/env nu

# LibreWolf clears cookies and site data on shutdown. Only a
# `persist-data-on-shutdown` ALLOW permission survives it, the one the
# "Manage Exceptions…" dialog writes; a `cookie` ALLOW permission does nothing.
# Those permissions live in the profile database, which cannot be symlinked, so
# this script writes them from librewolf/cookie-allow.txt instead.

use _lib.nu *

def main [] { apply-librewolf-cookie-exceptions (dotfiles-repo-dir) }

# Replaces the shutdown exceptions in the LibreWolf profile with the tracked list
export def apply-librewolf-cookie-exceptions [repo_dir] {
  let origins = (open $'($repo_dir)/librewolf/cookie-allow.txt'
    | lines
    | str trim
    | where { |l| ($l | is-not-empty) and (not ($l | str starts-with '#')) })

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
