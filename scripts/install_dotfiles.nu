#!/usr/bin/env nu

use _lib.nu *
use librewolf_init.nu *

# -------------- MAIN --------------

let repo_dir = (dotfiles-repo-dir)

let home_dir = if (is-windows) { $env.USERPROFILE } else { $env.HOME }
let config_dir = if (is-windows) { $env.LOCALAPPDATA } else { $'($env.HOME)/.config' }
let appdata_dir = if (is-windows) { $env.APPDATA } else { $'($env.HOME)/.config' }
let yazi_config_dir = if (is-windows) { $'($env.APPDATA)/yazi/config' } else { $'($config_dir)/yazi' }
let niri_config_dir = $'($config_dir)/niri'
let mpv_config_dir = if (is-windows) { $'($env.APPDATA)/mpv' } else { $'($config_dir)/mpv' }
let applications_dir = $'($home_dir)/.local/share/applications'

let symlinks = [
  { src: 'nvim',                          desc: 'nvim',                       dest: $'($config_dir)/nvim' }
  { src: 'git/.gitconfig',                desc: '.gitconfig',                 dest: $'($home_dir)/.gitconfig' }
  { src: 'ideavim/.ideavimrc',            desc: '.ideavimrc',                 dest: $'($home_dir)/.ideavimrc',                  skip_on_android: true }
  { src: 'wezterm/wezterm.lua',           desc: 'wezterm wezterm.lua',        dest: $'($home_dir)/.config/wezterm/wezterm.lua',     skip_on_android: true }
  { src: 'wezterm/nvim-splits.lua',       desc: 'wezterm nvim-splits.lua',    dest: $'($home_dir)/.config/wezterm/nvim-splits.lua', skip_on_android: true }
  { src: 'wezterm/keys.lua',              desc: 'wezterm keys.lua',           dest: $'($home_dir)/.config/wezterm/keys.lua',        skip_on_android: true }
  { src: 'zsh/.zshrc',                    desc: '.zshrc',                     dest: $'($home_dir)/.zshrc' }
  { src: 'yazi/yazi.toml',                desc: 'yazi yazi.toml',             dest: $'($yazi_config_dir)/yazi.toml' }
  { src: 'yazi/keymap.toml',              desc: 'yazi keymap.toml',           dest: $'($yazi_config_dir)/keymap.toml' }
  { src: 'yazi/theme.toml',               desc: 'yazi theme.toml',            dest: $'($yazi_config_dir)/theme.toml',           linux_only: true }
  { src: 'yazi/package.toml',             desc: 'yazi package.toml',          dest: $'($yazi_config_dir)/package.toml' }
  { src: 'yazi/init.lua',                 desc: 'yazi init.lua',              dest: $'($yazi_config_dir)/init.lua' }
  { src: 'yazi/local-plugins/tab-hover.yazi',   desc: 'yazi tab-hover plugin',   dest: $'($yazi_config_dir)/plugins/tab-hover.yazi' }
  { src: 'yazi/local-plugins/nu-notify.yazi',   desc: 'yazi nu-notify plugin',   dest: $'($yazi_config_dir)/plugins/nu-notify.yazi' }
  { src: 'yazi/local-plugins/disk-info.yazi',   desc: 'yazi disk-info plugin',   dest: $'($yazi_config_dir)/plugins/disk-info.yazi' }
  { src: 'yazi/local-plugins/file-info.yazi',   desc: 'yazi file-info plugin',   dest: $'($yazi_config_dir)/plugins/file-info.yazi' }
  { src: 'yazi/local-plugins/system-info.yazi', desc: 'yazi system-info plugin', dest: $'($yazi_config_dir)/plugins/system-info.yazi' }
  { src: 'niri/config.kdl',               desc: 'niri config.kdl',            dest: $'($niri_config_dir)/config.kdl',           linux_only: true }
  { src: 'niri/scripts',                  desc: 'niri scripts',               dest: $'($niri_config_dir)/scripts',              linux_only: true }
  { src: 'waybar',                        desc: 'waybar',                     dest: $'($config_dir)/waybar',                    linux_only: true }
  { src: 'swaylock',                      desc: 'swaylock',                   dest: $'($config_dir)/swaylock',                  linux_only: true }
  { src: 'wpaperd',                       desc: 'wpaperd',                    dest: $'($config_dir)/wpaperd',                   linux_only: true }
  { src: 'foot/foot.ini',                 desc: 'foot foot.ini',              dest: $'($config_dir)/foot/foot.ini',             linux_only: true }
  { src: 'fuzzel/fuzzel.ini',             desc: 'fuzzel fuzzel.ini',          dest: $'($config_dir)/fuzzel/fuzzel.ini',         linux_only: true }
  { src: 'mako/config',                   desc: 'mako config',                dest: $'($config_dir)/mako/config',               linux_only: true }
  { src: 'librewolf/tridactylrc',         desc: 'tridactylrc',                dest: $'($home_dir)/.tridactylrc',                skip_on_android: true }
  { src: 'mpv/mpv.conf',                  desc: 'mpv mpv.conf',               dest: $'($mpv_config_dir)/mpv.conf',                       skip_on_android: true }
  { src: 'mpv/scripts/sponsorblock.lua',  desc: 'mpv sponsorblock.lua',       dest: $'($mpv_config_dir)/scripts/sponsorblock.lua',       skip_on_android: true }
  { src: 'mpv/script-opts/sponsorblock.conf', desc: 'mpv sponsorblock.conf',  dest: $'($mpv_config_dir)/script-opts/sponsorblock.conf',  skip_on_android: true }
  { src: 'imv/config',                    desc: 'imv config',                 dest: $'($config_dir)/imv/config',                linux_only: true }
  { src: 'onlyoffice/onlyoffice-desktopeditors.desktop', desc: 'onlyoffice desktop entry', dest: $'($applications_dir)/onlyoffice-desktopeditors.desktop', linux_only: true }
  { src: 'starship/starship.toml',        desc: 'starship.toml',              dest: $'($home_dir)/.config/starship.toml' }
  { src: 'tinted-theming/tinty/config.toml', desc: 'tinty config.toml',       dest: $'($config_dir)/tinted-theming/tinty/config.toml',  linux_only: true }
  { src: 'btop/btop.conf',                desc: 'btop btop.conf',             dest: $'($config_dir)/btop/btop.conf' }
  { src: 'calcure/config.ini',            desc: 'calcure config.ini',         dest: $'($config_dir)/calcure/config.ini',         linux_only: true }
  { src: 'fastfetch',                     desc: 'fastfetch',                  dest: $'($config_dir)/fastfetch' }
  { src: 'nushell/config.nu',             desc: 'nushell config.nu',          dest: $'($appdata_dir)/nushell/config.nu' }
  { src: 'nushell/env.nu',                desc: 'nushell env.nu',             dest: $'($appdata_dir)/nushell/env.nu' }
  { src: 'nushell/scripts',               desc: 'nushell scripts',            dest: $'($appdata_dir)/nushell/scripts' }
  { src: 'nushell/android-vendor-autoload/yazi.nu', desc: 'android yazi vendor-autoload override', dest: $'($home_dir)/.local/share/nushell/vendor/autoload/yazi.nu', android_only: true }
  { src: 'claude/CLAUDE.md',              desc: 'claude CLAUDE.md',           dest: $'($home_dir)/.claude/CLAUDE.md' }
  { src: 'claude/settings.json',          desc: 'claude settings.json',       dest: $'($home_dir)/.claude/settings.json' }
  { src: 'claude/statusline-command.sh',  desc: 'claude statusline-command.sh', dest: $'($home_dir)/.claude/statusline-command.sh' }
  { src: 'claude/skills',                 desc: 'claude skills',              dest: $'($home_dir)/.claude/skills' }
  { src: 'claude/agents',                 desc: 'claude agents',              dest: $'($home_dir)/.claude/agents' }
  { src: 'claude/rules',                  desc: 'claude rules',               dest: $'($home_dir)/.claude/rules' }
  { src: 'claude/hooks',                  desc: 'claude hooks',               dest: $'($home_dir)/.claude/hooks' }
]

if (is-windows) { windows-require-symlink-capability }

for s in ($symlinks | where { |s|
  let skip_android = ($s.skip_on_android? | default false) and (is-android)
  let android_only = ($s.android_only? | default false) and (not (is-android))
  let linux_only = ($s.linux_only? | default false) and (not (is-linux))
  not ($skip_android or $android_only or $linux_only)
}) {
  create-symbolic-link $'($repo_dir)/($s.src)' $s.dest $s.desc
}

install-yazi-packages

install-bat-syntaxes

init-librewolf $repo_dir

ensure-gitconfig-local $home_dir

if (is-windows) { allow-cfa-apps-if-needed }

# -------------- FUNCTIONS --------------

# Installs yazi plugins via `ya pkg install` (no-op if `ya` is missing)
def install-yazi-packages [] {
  if (which ya | is-empty) {
    warn 'ya CLI not found on PATH. Skipping yazi plugin install — install yazi, then rerun this script (or run `ya pkg install`).'
    return
  }
  print 'Installing yazi plugins via `ya pkg install`'
  try {
    ^ya pkg install
  } catch { |e|
    warn $'ya pkg install failed: ($e.msg)'
  }
}

# Downloads the Nushell sublime-syntax into bat's config dir and rebuilds cache
# so .nu files get syntax highlighting (used by yazi's piper previewer).
def install-bat-syntaxes [] {
  if (which bat | is-empty) {
    warn 'bat not found on PATH. Skipping Nushell syntax install.'
    return
  }
  # `which` can report an entry (stale shim, cross-user binary, App Execution
  # Alias stub) that then fails to actually spawn — probe before using.
  let probe = try {
    { ok: true, langs: (^bat --list-languages | lines) }
  } catch { |e|
    { ok: false, err: ($e.msg | str trim) }
  }
  if not $probe.ok {
    warn $'bat is on PATH but cannot run: ($probe.err). Skipping Nushell syntax install.'
    return
  }
  if ($probe.langs | any { |l| $l =~ '^Nushell:' }) { return }
  let syntaxes_dir = $'(^bat --config-dir | str trim)/syntaxes'
  if not ($syntaxes_dir | path exists) { mkdir $syntaxes_dir }
  let target = $'($syntaxes_dir)/nushell.sublime-syntax'
  print $'Downloading Nushell sublime-syntax to ($target)'
  try {
    http get 'https://raw.githubusercontent.com/stevenxxiu/sublime_text_nushell/master/nushell.sublime-syntax' | save -f $target
    print 'Rebuilding bat cache'
    ^bat cache --build
  } catch { |e|
    warn $'bat syntax install failed: ($e.msg)'
  }
}

# Creates ~/.gitconfig-local with the default user info if it doesn't exist
def ensure-gitconfig-local [home_dir] {
  let gitconfig_local = $'($home_dir)/.gitconfig-local'
  if ($gitconfig_local | path exists) { return }
  print 'Creating .gitconfig-local with default user'
  "[user]\n\tname = Ylniss\n\temail = zupqa0@gmail.com\n" | save $gitconfig_local
}

# -------------- WINDOWS --------------

# True if Windows Developer Mode is enabled (allows symlinks without admin)
def windows-dev-mode-enabled [] {
  let script = 'try { (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop).AllowDevelopmentWithoutDevLicense } catch { "0" }'
  (^powershell -NoProfile -Command $script | str trim) == "1"
}

# True if Windows Defender Controlled Folder Access is enabled
def windows-cfa-enabled [] {
  try {
    (^powershell -NoProfile -Command "(Get-MpPreference).EnableControlledFolderAccess" | str trim) != "0"
  } catch { |e|
    warn $'Could not check Controlled Folder Access state: ($e.msg | str trim). Skipping CFA allow-list step.'
    false
  }
}

# Errors out unless admin or Developer Mode is enabled
def windows-require-symlink-capability [] {
  if (is-elevated) or (windows-dev-mode-enabled) { return }
  error make { msg: "Cannot create symbolic links. Enable Developer Mode (Settings > System > For developers) or run this script as Administrator." }
}

# Adds one executable to the Defender CFA allow-list
def allow-cfa-app [exe_path, app_name] {
  ^powershell -NoProfile -Command $"Add-MpPreference -ControlledFolderAccessAllowedApplications '($exe_path)'"
  print $'Allowed ($app_name) through Controlled Folder Access'
}

# Allows yazi/nushell through CFA so they can delete files in protected folders; prints manual instructions if not elevated
def allow-cfa-apps-if-needed [] {
  if not (windows-cfa-enabled) { return }

  let apps = [
    { name: 'yazi', cmd: 'yazi' }
    { name: 'nushell', cmd: 'nu' }
  ]
  let resolved = $apps | each { |a|
    let r = (which $a.cmd)
    if ($r | is-empty) { null } else { { name: $a.name, path: ($r | get 0.path) } }
  } | compact

  if ($resolved | is-empty) { return }

  if (is-elevated) {
    for a in $resolved { allow-cfa-app $a.path $a.name }
    return
  }

  warn 'Controlled Folder Access is enabled. Run in an elevated PowerShell to allow these:'
  for a in $resolved { print $"  Add-MpPreference -ControlledFolderAccessAllowedApplications '($a.path)'" }
}
