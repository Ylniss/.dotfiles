if $nu.os-info.family =~ windows {
  $env.repo = $"($env.USERPROFILE)/stuff/repo"
  $env.games = $"($env.USERPROFILE)/stuff/games"
  $env.downloads = $"($env.USERPROFILE)/stuff/downloads"
  $env.notes = $"($env.USERPROFILE)/stuff/knowtes"
} else {
  $env.repo = $"($env.HOME)/stuff/repo"
  $env.games = $"($env.HOME)/stuff/games"
  $env.downloads = $"($env.HOME)/stuff/downloads"
  $env.notes = $"($env.HOME)/stuff/knowtes"
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling plugin add
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

if $nu.os-info.family =~ windows {
  $env.Path = ($env.Path | split row (char esep) | prepend $'($env.LOCALAPPDATA)\nvim-data\mason\packages\delve')
  let aseprite_dir = 'C:\Program Files\Aseprite'
  if ($aseprite_dir | path exists) {
    $env.Path = ($env.Path | prepend $aseprite_dir)
  }
}


$env.RIPGREP_CONFIG_PATH = $'($env.repo)/.dotfiles/.ripgreprc' 
$env.FZF_DEFAULT_COMMAND = 'fd -H'
$env.GIT_EDITOR = 'nvim'

# Setup Android env
if $nu.os-info.name =~ android {
  $env.storage = "~/storage"
  $env.camera = "~/storage/dcim/camera"
}

# Start ssh-agent
^ssh-agent -c
    | lines
    | first 2
    | parse "setenv {name} {value};"
    | transpose -r
    | into record
    | load-env

if $nu.os-info.name == 'android' {
  do { ^ssh-add ~/.ssh/andrd } | ignore
}

# Setup custom prompt - Starship (delete cache file to regenerate after starship update)
let starship_cache = ($"($nu.home-dir)/.cache/starship" | path expand)
if not ($"($starship_cache)/init.nu" | path exists) {
    mkdir $starship_cache
    starship init nu | save -f $"($starship_cache)/init.nu"
}
