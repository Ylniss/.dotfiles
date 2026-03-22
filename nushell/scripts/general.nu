alias repo = cd $env.repo
alias games = cd $env.games
alias dwn = cd $env.downloads

# Make directory and enter inside
def mkdircd --env [dirName: string] {
  mkdir $dirName
  cd $dirName
}

# -------------- NVIM --------------

alias vi = nvim
alias vim = nvim

# -------------- LF --------------- 

# Change directory into path that lf exits on
def lfcd --env [] {
  let tmp = (mktemp)
  lf -last-dir-path $tmp
  try {
    let target_dir = (open --raw $tmp)
    rm -f $tmp
    try {
      if ($target_dir != $env.PWD) { cd $target_dir }
    } catch { |e| print -e $'lfcd: Can not change to ($target_dir): ($e | get debug)' }
  } catch {
    |e| print -e $'lfcd: Reading ($tmp) returned an error: ($e | get debug)'
  }
}

alias lf = lfcd

# -------------- CLIPBOARD --------------

# Pipe input to system clipboard
def clip [] {
  let input = $in
  if $nu.os-info.family == 'windows' {
    $input | ^clip
  } else if $nu.os-info.name == 'macos' {
    $input | pbcopy
  } else {
    $input | xclip -selection clipboard
  }
}

# -------------- EXTRACT --------------

# Extract archive based on file extension
def extract [file: path] {
  let ext = ($file | str downcase)
  if ($ext | str ends-with ".tar.gz") or ($ext | str ends-with ".tgz") {
    tar -xzf $file
  } else if ($ext | str ends-with ".tar.bz2") {
    tar -xjf $file
  } else if ($ext | str ends-with ".tar.xz") {
    tar -xJf $file
  } else if ($ext | str ends-with ".tar") {
    tar -xf $file
  } else if ($ext | str ends-with ".zip") {
    unzip $file
  } else if ($ext | str ends-with ".7z") {
    7z x $file
  } else if ($ext | str ends-with ".rar") {
    unrar x $file
  } else {
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
  if $nu.os-info.family == 'windows' {
    $local_ip = (ipconfig | rg "IPv4" | rg '\d+\.\d+\.\d+\.\d+' -oN | lines | first)
  } else {
    $local_ip = (hostname -I | split row ' ' | first)
  }
  {local: $local_ip, public: $public_ip}
}
