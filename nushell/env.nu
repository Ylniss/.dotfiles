def is-windows [] { $nu.os-info.family == 'windows' }
def is-android [] { $nu.os-info.name == 'android' }
def is-macos   [] { $nu.os-info.name == 'macos' }

$env.REPO = $"($nu.home-dir)/stuff/repo"
$env.GAMES = $"($nu.home-dir)/stuff/games"
$env.DOWNLOADS = $"($nu.home-dir)/stuff/downloads"
$env.NOTES = $"($nu.home-dir)/stuff/knowtes"

if (is-windows) {
  $env.Path = ($env.Path | prepend $'($env.LOCALAPPDATA)\nvim-data\mason\packages\delve')
  $env.Path ++= (['C:\Program Files\Aseprite' 'C:\Program Files\Audacity 4\bin' 'C:\Program Files\Inkscape\bin' 'C:\Program Files\GIMP 3\bin' $'($env.LOCALAPPDATA)\Programs\GIMP 3\bin'] | where { path exists })
}
$env.PATH = ($env.PATH | prepend ($nu.home-dir | path join 'go' 'bin'))


$env.RIPGREP_CONFIG_PATH = $'($env.REPO)/.dotfiles/ripgrep/.ripgreprc'
$env.FZF_DEFAULT_COMMAND = 'fd -H'

$env.GIT_EDITOR = 'nvim'
$env.EDITOR = 'nvim'

$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

# lazygit + fzf base16 themes via tinty
if not (is-windows) and not (is-android) {
  $env.LG_CONFIG_FILE = $"($env.HOME)/.local/share/tinted-theming/tinty/tinted-lazygit-themes-file.yml"

  let fzf_colors_file = $"($env.HOME)/.local/share/tinted-theming/tinty/fzf-colors"
  if ($fzf_colors_file | path exists) {
    $env.FZF_DEFAULT_OPTS = (open $fzf_colors_file | str trim)
  }
}

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
        | transpose -rd
        | load-env
}

if (is-android) {
  do { ^ssh-add ~/.ssh } | ignore
}

# config.nu imports init.nu at parse time, so generate it here.
# After a Starship update, delete init.nu to regenerate it.
let starship_cache = ($"($nu.home-dir)/.cache/starship" | path expand)
if not ($"($starship_cache)/init.nu" | path exists) {
    mkdir $starship_cache
    starship init nu | save -f $"($starship_cache)/init.nu"
}
