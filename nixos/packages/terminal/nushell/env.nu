def is-windows [] { $nu.os-info.family == 'windows' }
def is-android [] { $nu.os-info.name == 'android' }
def is-macos   [] { $nu.os-info.name == 'macos' }

let stuff_root = if (is-windows) { $env.USERPROFILE } else { $env.HOME }

$env.REPO = $"($stuff_root)/stuff/repo"
$env.GAMES = $"($stuff_root)/stuff/games"
$env.DOWNLOADS = $"($stuff_root)/stuff/downloads"
$env.NOTES = $"($stuff_root)/stuff/knowtes"

# Script/plugin lookup dirs — skip if already set (e.g. by NixOS home-manager).
if ($env.NU_LIB_DIRS? | is-empty) {
  $env.NU_LIB_DIRS = [($nu.default-config-dir | path join 'scripts')]
}
if ($env.NU_PLUGIN_DIRS? | is-empty) {
  $env.NU_PLUGIN_DIRS = [($nu.default-config-dir | path join 'plugins')]
}

if (is-windows) {
  $env.Path = ($env.Path | split row (char esep) | prepend $'($env.LOCALAPPDATA)\nvim-data\mason\packages\delve')
  let aseprite_dir = 'C:\Program Files\Aseprite'
  if ($aseprite_dir | path exists) {
    $env.Path = ($env.Path | prepend $aseprite_dir)
  }
  $env.Path = ($env.Path | prepend ($nu.home-dir | path join 'go' 'bin'))
} else {
  $env.PATH = ($env.PATH | prepend ($nu.home-dir | path join 'go' 'bin'))
}


$env.RIPGREP_CONFIG_PATH = $'($env.REPO)/.dotfiles/ripgrep/.ripgreprc'
$env.FZF_DEFAULT_COMMAND = 'fd -H'
$env.GIT_EDITOR = 'nvim'

$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

# Setup Android env
if (is-android) {
  $env.STORAGE = "~/storage"
  $env.CAMERA = "~/storage/dcim/camera"
}

# Start ssh-agent — skip if one is already inherited, else every shell forks a new agent.
if ($env.SSH_AUTH_SOCK? | is-empty) {
    ^ssh-agent -c
        | lines
        | first 2
        | parse "setenv {name} {value};"
        | transpose -r
        | into record
        | load-env
}

if (is-android) {
  do { ^ssh-add ~/.ssh/andrd } | ignore
}

# Setup custom prompt - Starship (delete cache file to regenerate after starship update)
let starship_cache = ($"($nu.home-dir)/.cache/starship" | path expand)
if not ($"($starship_cache)/init.nu" | path exists) {
    mkdir $starship_cache
    starship init nu | save -f $"($starship_cache)/init.nu"
}
