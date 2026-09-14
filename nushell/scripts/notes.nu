def --env notes [] { cd $env.NOTES }

# Sync notes with remote: commit dirty changes, rebase, push.
# Toasts via `notify` and exits non-zero on failure.
def "notes up" [] {
  cd $env.NOTES

  try { git fetch --quiet } catch { |e|
    notify "notes up" $"fetch failed: ($e.msg)"
    error make "notes up: fetch failed"
  }

  let branch = (git rev-parse --abbrev-ref HEAD)
  let upstream = $"origin/($branch)"

  let dirty = (git status --porcelain)
  if ($dirty | is-not-empty) {
    try {
      git add .
      git commit --quiet -m "update"
    } catch { |e|
      notify "notes up" $"commit failed: ($e.msg)"
      error make "notes up: commit failed"
    }
  }

  let behind = (git rev-list --count $"HEAD..($upstream)" | into int)
  if $behind > 0 {
    try { git rebase --quiet $upstream } catch {
      notify "notes up" "rebase failed — resolve manually"
      error make "notes up: rebase failed"
    }
  }

  let ahead = (git rev-list --count $"($upstream)..HEAD" | into int)
  if $ahead > 0 {
    try { git push --quiet } catch { |e|
      notify "notes up" $"push failed: ($e.msg)"
      error make "notes up: push failed"
    }
  }

  print $"(ansi green_bold)notes synced(ansi reset) — (ansi cyan)↑ ($ahead)(ansi reset) uploaded, (ansi yellow)↓ ($behind)(ansi reset) downloaded"
}
