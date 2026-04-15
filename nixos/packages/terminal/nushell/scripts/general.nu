# Change directory to repo, optionally into a subdirectory
def --env repo [subdir?: string] {
  let target = if $subdir == null { $env.repo } else { $env.repo | path join $subdir }
  if not ($target | path exists) {
    print -e $"repo: directory does not exist: ($target)"
    return
  }
  cd $target
}

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
