# Change directory to repo, optionally into a subdirectory
def --env repo [subdir: string = ""] {
  let target = ($env.REPO | path join $subdir)
  cd $target
}

alias games = cd $env.GAMES
alias dwn = cd $env.DOWNLOADS
alias knowtes = cd $env.NOTES

# List files with mode permissions
def lsmod [path: glob = "."] { ls -al $path | select name type size modified mode }

# Make directory and enter inside
def --env mkdircd [dir_name: string] {
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
  } else if ($env.WAYLAND_DISPLAY? | is-not-empty) {
    # On Wayland xclip only reaches XWayland clients, so native apps cannot read the clipboard.
    $input | wl-copy
  } else {
    $input | xclip -selection clipboard
  }
}

# -------------- EXTRACT --------------

# Extract archive into directory named after the archive
def extract [file: path] {
  let name_parts = ($file | path basename | parse -r '(?i)^(?<dir>.*?)\.(?<ext>tar\.(?:gz|bz2|xz)|tgz|zip|7z|rar|tar)$')
  if ($name_parts | is-empty) {
    print $"Unsupported archive format: ($file)"
    return
  }
  let dir = $name_parts.0.dir

  mkdir $dir

  match ($name_parts.0.ext | str lowercase) {
    'tar.gz' | 'tgz' => { tar -xzf $file -C $dir }
    'tar.bz2' => { tar -xjf $file -C $dir }
    'tar.xz' => { tar -xJf $file -C $dir }
    'tar' => { tar -xf $file -C $dir }
    'zip' => {
      if (is-windows) {
        tar -xf $file -C $dir
      } else {
        unzip $file -d $dir
      }
    }
    '7z' => { 7z x $file $"-o($dir)" }
    'rar' => { unrar x $file $"($dir)/" }
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
