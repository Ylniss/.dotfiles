# Change directory to repo, optionally into a subdirectory
def --env repo [subdir?: string] {
  let target = if $subdir == null { $env.REPO } else { $env.REPO | path join $subdir }
  if not ($target | path exists) {
    print -e $"repo: directory does not exist: ($target)"
    return
  }
  cd $target
}

alias games = cd $env.GAMES
alias dwn = cd $env.DOWNLOADS
alias knowtes = cd $env.NOTES

# List files with mode permissions
def lsmod [path: glob = "."] { ls -al $path | select name type size modified mode }

def --env notes [] { cd $env.NOTES }

# Sync notes with remote: commit dirty changes, rebase, push.
# Toasts via `notify` and exits non-zero on failure.
def "notes up" [] {
  cd $env.NOTES

  try { git fetch --quiet } catch { |e|
    notify "notes up" $"fetch failed: ($e.msg)"
    error make { msg: "notes up: fetch failed" }
  }

  let branch = (git rev-parse --abbrev-ref HEAD | str trim)
  let upstream = $"origin/($branch)"

  let dirty = (git status --porcelain | str trim)
  if ($dirty | is-not-empty) {
    try {
      git add .
      git commit --quiet -m "update"
    } catch { |e|
      notify "notes up" $"commit failed: ($e.msg)"
      error make { msg: "notes up: commit failed" }
    }
  }

  let behind = (git rev-list --count $"HEAD..($upstream)" | str trim | into int)
  if $behind > 0 {
    try { git rebase --quiet $upstream } catch { |e|
      notify "notes up" "rebase failed — resolve manually"
      error make { msg: "notes up: rebase failed" }
    }
  }

  let ahead = (git rev-list --count $"($upstream)..HEAD" | str trim | into int)
  if $ahead > 0 {
    try { git push --quiet } catch { |e|
      notify "notes up" $"push failed: ($e.msg)"
      error make { msg: "notes up: push failed" }
    }
  }

  print $"(ansi green_bold)notes synced(ansi reset) — (ansi cyan)↑ ($ahead)(ansi reset) uploaded, (ansi yellow)↓ ($behind)(ansi reset) downloaded"
}

# Make directory and enter inside
def mkdircd --env [dir_name: string] {
  mkdir $dir_name
  cd $dir_name
}

# -------------- CLIPBOARD --------------

# Pipe input to system clipboard
def clip [] {
  let input = $in
  if (is-windows) {
    $input | ^clip
  } else if (is-macos) {
    $input | pbcopy
  } else {
    $input | xclip -selection clipboard
  }
}

# -------------- EXTRACT --------------

# Extract archive into directory named after the archive
def extract [file: path] {
  let ext = ($file | str lowercase)
  let dir = ($file | path basename | str replace -r '(?i)\.(tar\.(gz|bz2|xz)|tgz|zip|7z|rar|tar)$' '')

  mkdir $dir

  if ($ext | str ends-with ".tar.gz") or ($ext | str ends-with ".tgz") {
    tar -xzf $file -C $dir
  } else if ($ext | str ends-with ".tar.bz2") {
    tar -xjf $file -C $dir
  } else if ($ext | str ends-with ".tar.xz") {
    tar -xJf $file -C $dir
  } else if ($ext | str ends-with ".tar") {
    tar -xf $file -C $dir
  } else if ($ext | str ends-with ".zip") {
    if (is-windows) {
      tar -xf $file -C $dir
    } else {
      unzip $file -d $dir
    }
  } else if ($ext | str ends-with ".7z") {
    7z x $file $"-o($dir)"
  } else if ($ext | str ends-with ".rar") {
    unrar x $file $"($dir)/"
  } else {
    rm -r $dir
    print $"Unsupported archive format: ($file)"
  }
}

# -------------- NETWORK --------------

# Show LAN and public IP addresses (LAN = source IP of the default route,
# so VPN/VM virtual adapters are skipped).
def lsip [] {
  let public_ip = (http get https://ifconfig.me/ip | str trim)
  let local_ip = if (is-windows) {
    ^powershell -NoProfile -Command "(Find-NetRoute -RemoteIPAddress '1.1.1.1' | Select-Object -First 1).IPAddress" | str trim
  } else if (is-macos) {
    let iface = (^route -n get 1.1.1.1 | parse --regex 'interface:\s+(?P<i>\S+)' | get 0.i)
    ^ipconfig getifaddr $iface | str trim
  } else if (is-android) {
    # Android SELinux blocks unprivileged netlink, so `ip route get` fails.
    # UDP connect() picks the egress IP without sending; getsockname() reads it.
    ^python3 -c "import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.connect(('1.1.1.1',80));print(s.getsockname()[0])" | str trim
  } else {
    ^ip route get 1.1.1.1 | parse --regex 'src\s+(?P<ip>\d+\.\d+\.\d+\.\d+)' | get 0.ip
  }
  {local: $local_ip, public: $public_ip}
}
