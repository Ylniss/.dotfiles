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

def --env notes [] { cd $env.NOTES }

# Sync notes repo: commit local changes as "update", rebase onto remote, then push.
# Reports how many commits were uploaded and downloaded.
def "notes up" [] {
  cd $env.NOTES

  git fetch --quiet

  let branch = (git rev-parse --abbrev-ref HEAD | str trim)
  let upstream = $"origin/($branch)"

  let dirty = (git status --porcelain | str trim)
  if ($dirty | is-not-empty) {
    git add .
    git commit --quiet -m "update"
  }

  let behind = (git rev-list --count $"HEAD..($upstream)" | str trim | into int)
  if $behind > 0 {
    git rebase --quiet $upstream
  }

  let ahead = (git rev-list --count $"($upstream)..HEAD" | str trim | into int)
  if $ahead > 0 {
    git push --quiet
  }

  print $"(ansi green_bold)notes synced(ansi reset) — (ansi cyan)↑ ($ahead)(ansi reset) uploaded, (ansi yellow)↓ ($behind)(ansi reset) downloaded"
}

# Make directory and enter inside
def mkdircd --env [dir_name: string] {
  mkdir $dir_name
  cd $dir_name
}

# -------------- NVIM --------------

alias vi = nvim
alias vim = nvim

# Remove stale nvim shada temp files
def virmtmp [] {
  let shada_dir = if (is-windows) {
    $"($env.LOCALAPPDATA)/nvim-data/shada"
  } else {
    $"($nu.home-dir)/.local/share/nvim/shada"
  }
  glob ($shada_dir | path join "main.shada.tmp.*" | str replace --all '\' '/') | each { rm $in } | ignore
}

# -------------- YAZI ---------------

# cd into yazi's exit path. On termux this is overridden by an extern in
# `/usr/share/nushell/vendor/autoload/yazi.nu`; see `android-vendor-autoload/yazi.nu`.
def --env yazi [...args] {
  let tmp = (mktemp)
  ^yazi ...$args --cwd-file $tmp
  try {
    let target_dir = (open --raw $tmp | str trim)
    rm -f $tmp
    try {
      if ($target_dir != "" and $target_dir != $env.PWD) { cd $target_dir }
    } catch { |e| print -e $'yazi: Can not change to ($target_dir): ($e | get debug)' }
  } catch {
    |e| print -e $'yazi: Reading ($tmp) returned an error: ($e | get debug)'
  }
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
  let ext = ($file | str downcase)
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

# -------------- WEZTERM LAYOUTS --------------

# Create dev layout: 60/40 vertical split, right pane split 80/20 horizontal
def layout-dev [] {
  let pane_id = $env.WEZTERM_PANE
  let right_pane = (wezterm cli split-pane --right --percent 40 --pane-id $pane_id)
  wezterm cli split-pane --bottom --percent 20 --pane-id $right_pane
  wezterm cli activate-pane --pane-id $pane_id
}

# -------------- NETWORK --------------

# Show local and public IP addresses
def ip [] {
  let public_ip = (http get https://ifconfig.me/ip | str trim)
  mut local_ip = "unknown"
  if (is-windows) {
    $local_ip = (ipconfig | rg "IPv4" | rg '\d+\.\d+\.\d+\.\d+' -oN | lines | first)
  } else {
    $local_ip = (hostname -I | split row ' ' | first)
  }
  {local: $local_ip, public: $public_ip}
}
