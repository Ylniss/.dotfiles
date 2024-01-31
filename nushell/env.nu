if $nu.os-info.family =~ windows {
  $env.repo = $"($env.USERPROFILE)/stuff/repo"
  $env.games = $"($env.USERPROFILE)/stuff/games"
  $env.downloads = $"($env.USERPROFILE)/stuff/downloads"
} else {
  $env.repo = $"($env.HOME)/stuff/repo"
  $env.games = $"($env.HOME)/stuff/games"
  $env.downloads = $"($env.HOME)/stuff/downloads"
}

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

$env.RIPGREP_CONFIG_PATH = $'($env.repo)/.dotfiles/.ripgreprc' 

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

# Setup custom prompt - Starship
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
