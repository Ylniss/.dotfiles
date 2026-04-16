def is-windows [] { $nu.os-info.family == 'windows' }
def is-android [] { $nu.os-info.name == 'android' }
def is-macos   [] { $nu.os-info.name == 'macos' }

if (is-windows) {
  $env.REPO = $"($env.USERPROFILE)/stuff/repo"
  $env.GAMES = $"($env.USERPROFILE)/stuff/games"
  $env.DOWNLOADS = $"($env.USERPROFILE)/stuff/downloads"
  $env.NOTES = $"($env.USERPROFILE)/stuff/knowtes"
} else {
  $env.REPO = $"($env.HOME)/stuff/repo"
  $env.GAMES = $"($env.HOME)/stuff/games"
  $env.DOWNLOADS = $"($env.HOME)/stuff/downloads"
  $env.NOTES = $"($env.HOME)/stuff/knowtes"
}

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


$env.RIPGREP_CONFIG_PATH = $'($env.REPO)/.dotfiles/.ripgreprc'
$env.FZF_DEFAULT_COMMAND = 'fd -H'
$env.GIT_EDITOR = 'nvim'

# Setup Android env
if (is-android) {
  $env.STORAGE = "~/storage"
  $env.CAMERA = "~/storage/dcim/camera"
}

# Start ssh-agent
^ssh-agent -c
    | lines
    | first 2
    | parse "setenv {name} {value};"
    | transpose -r
    | into record
    | load-env

if (is-android) {
  do { ^ssh-add ~/.ssh/andrd } | ignore
}

# Setup custom prompt - Starship (delete cache file to regenerate after starship update)
let starship_cache = ($"($nu.home-dir)/.cache/starship" | path expand)
if not ($"($starship_cache)/init.nu" | path exists) {
    mkdir $starship_cache
    starship init nu | save -f $"($starship_cache)/init.nu"
}
