#!/usr/bin/env nu

# -------------- MAIN --------------

let repo_dir = (get-dotfiles-repo-dir)

let home_dir = if (is-windows) { $env.USERPROFILE } else { $env.HOME }
let config_dir = if (is-windows) { $env.LOCALAPPDATA } else { $'($env.HOME)/.config' }
let appdata_dir = if (is-windows) { $env.APPDATA } else { $'($env.HOME)/.config' }
let yazi_config_dir = if (is-windows) { $'($env.APPDATA)/yazi/config' } else { $'($config_dir)/yazi' }
let niri_config_dir = $'($config_dir)/niri'
let qutebrowser_config_dir = if (is-windows) { $'($env.APPDATA)/qutebrowser/config' } else { $'($config_dir)/qutebrowser' }
let mpv_config_dir = if (is-windows) { $'($env.APPDATA)/mpv' } else { $'($config_dir)/mpv' }
let obsidian_data_dir = if (is-windows) { $'($env.APPDATA)/obsidian' } else if (is-macos) { $'($env.HOME)/Library/Application Support/obsidian' } else { $'($env.HOME)/.config/obsidian' }

let symlinks = [
  { src: 'nvim',                          desc: 'nvim',                       dest: $'($config_dir)/nvim' }
  { src: 'git/.gitconfig',                desc: '.gitconfig',                 dest: $'($home_dir)/.gitconfig' }
  { src: 'ideavim/.ideavimrc',            desc: '.ideavimrc',                 dest: $'($home_dir)/.ideavimrc',                  skip_on_android: true }
  { src: 'wezterm/.wezterm.lua',          desc: '.wezterm.lua',               dest: $'($home_dir)/.wezterm.lua',                skip_on_android: true }
  { src: 'zsh/.zshrc',                    desc: '.zshrc',                     dest: $'($home_dir)/.zshrc' }
  { src: 'yazi/yazi.toml',                desc: 'yazi yazi.toml',             dest: $'($yazi_config_dir)/yazi.toml' }
  { src: 'yazi/keymap.toml',              desc: 'yazi keymap.toml',           dest: $'($yazi_config_dir)/keymap.toml' }
  { src: 'yazi/theme.toml',               desc: 'yazi theme.toml',            dest: $'($yazi_config_dir)/theme.toml' }
  { src: 'yazi/package.toml',             desc: 'yazi package.toml',          dest: $'($yazi_config_dir)/package.toml' }
  { src: 'yazi/init.lua',                 desc: 'yazi init.lua',              dest: $'($yazi_config_dir)/init.lua' }
  { src: 'yazi/local-plugins/tab-hover.yazi',   desc: 'yazi tab-hover plugin',   dest: $'($yazi_config_dir)/plugins/tab-hover.yazi' }
  { src: 'yazi/local-plugins/disk-info.yazi',   desc: 'yazi disk-info plugin',   dest: $'($yazi_config_dir)/plugins/disk-info.yazi' }
  { src: 'yazi/local-plugins/file-info.yazi',   desc: 'yazi file-info plugin',   dest: $'($yazi_config_dir)/plugins/file-info.yazi' }
  { src: 'yazi/local-plugins/system-info.yazi', desc: 'yazi system-info plugin', dest: $'($yazi_config_dir)/plugins/system-info.yazi' }
  { src: 'niri/config.kdl',               desc: 'niri config.kdl',            dest: $'($niri_config_dir)/config.kdl',           linux_only: true }
  { src: 'niri/scripts',                  desc: 'niri scripts',               dest: $'($niri_config_dir)/scripts',              linux_only: true }
  { src: 'foot/foot.ini',                 desc: 'foot foot.ini',              dest: $'($config_dir)/foot/foot.ini',             linux_only: true }
  { src: 'qutebrowser/config.py',         desc: 'qutebrowser config.py',      dest: $'($qutebrowser_config_dir)/config.py',     skip_on_android: true }
  { src: 'mpv/mpv.conf',                  desc: 'mpv mpv.conf',               dest: $'($mpv_config_dir)/mpv.conf',                       skip_on_android: true }
  { src: 'mpv/scripts/sponsorblock.lua',  desc: 'mpv sponsorblock.lua',       dest: $'($mpv_config_dir)/scripts/sponsorblock.lua',       skip_on_android: true }
  { src: 'mpv/script-opts/sponsorblock.conf', desc: 'mpv sponsorblock.conf',  dest: $'($mpv_config_dir)/script-opts/sponsorblock.conf',  skip_on_android: true }
  { src: 'starship/starship.toml',        desc: 'starship.toml',              dest: $'($home_dir)/.config/starship.toml' }
  { src: 'btop/btop.conf',                desc: 'btop btop.conf',             dest: $'($config_dir)/btop/btop.conf' }
  { src: 'nushell/config.nu',             desc: 'nushell config.nu',          dest: $'($appdata_dir)/nushell/config.nu' }
  { src: 'nushell/env.nu',                desc: 'nushell env.nu',             dest: $'($appdata_dir)/nushell/env.nu' }
  { src: 'nushell/scripts',               desc: 'nushell scripts',            dest: $'($appdata_dir)/nushell/scripts' }
  { src: 'nushell/android-vendor-autoload/yazi.nu', desc: 'android yazi vendor-autoload override', dest: $'($home_dir)/.local/share/nushell/vendor/autoload/yazi.nu', android_only: true }
  { src: 'claude/CLAUDE.md',              desc: 'claude CLAUDE.md',           dest: $'($home_dir)/.claude/CLAUDE.md' }
  { src: 'claude/settings.json',          desc: 'claude settings.json',       dest: $'($home_dir)/.claude/settings.json' }
  { src: 'claude/statusline-command.sh',  desc: 'claude statusline-command.sh', dest: $'($home_dir)/.claude/statusline-command.sh' }
  { src: 'claude/skills',                 desc: 'claude skills',              dest: $'($home_dir)/.claude/skills' }
  { src: 'claude/agents',                 desc: 'claude agents',              dest: $'($home_dir)/.claude/agents' }
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

if not (is-android) {
  copy-file $'($repo_dir)/obsidian/Custom Dictionary.txt' $'($obsidian_data_dir)/Custom Dictionary.txt' 'obsidian Custom Dictionary.txt'
}

install-yazi-packages

install-bat-syntaxes

ensure-gitconfig-local $home_dir

if (is-windows) { allow-cfa-apps-if-needed }

# -------------- FUNCTIONS --------------

def is-windows [] { $nu.os-info.family == 'windows' }
def is-android [] { $nu.os-info.name == 'android' }
def is-macos   [] { $nu.os-info.name == 'macos' }
def is-linux   [] { $nu.os-info.name == 'linux' }

# Prints a yellow warning to stderr
def warn [msg: string] {
  print -e $"(ansi yellow)($msg)(ansi reset)"
}

# Returns the dotfiles repo directory for this platform
def get-dotfiles-repo-dir [] {
  if (is-windows) {
    $'($env.USERPROFILE)/stuff/repo/.dotfiles'
  } else {
    $'($env.HOME)/stuff/repo/.dotfiles'
  }
}

# Reads where a symlink points (lists parent so directory symlinks aren't followed into)
def read-symlink-target [link_path] {
  let parent = ($link_path | path dirname)
  let basename = ($link_path | path basename)
  let matches = try {
    ls --long $parent | where { |r| ($r.name | path basename) == $basename }
  } catch { [] }
  if ($matches | is-empty) { '' } else { ($matches | first | get target? | default '') }
}

# True if two paths point to the same location (case/slash-insensitive on Windows)
def same-path [a: string, b: string] {
  if (is-windows) {
    ($a | str replace --all '\' '/' | str downcase) == ($b | str replace --all '\' '/' | str downcase)
  } else {
    $a == $b
  }
}

# Creates a symlink, replacing existing file/dir; on Windows clears stale ancestor reparse points first
def create-symbolic-link [target, link_path, description] {
  # Remove any ancestor reparse point first so rm/mkdir below don't follow it
  # into its target.
  if (is-windows) {
    mut anc = ($link_path | path dirname)
    mut stale = ''
    loop {
      if ($anc | path exists -n) and (($anc | path type) == 'symlink') {
        $stale = $anc
        break
      }
      let up = ($anc | path dirname)
      if $up == $anc { break }
      $anc = $up
    }
    if ($stale | is-not-empty) {
      print $'Removing stale directory symlink before linking ($description): ($stale)'
      windows-delete-reparse $stale
    }
  }

  let is_symlink = ($link_path | path exists -n) and (($link_path | path type) == 'symlink')

  if $is_symlink {
    let current_target = (read-symlink-target $link_path)
    if (same-path $current_target $target) {
      print $'($description) (ansi blue)symbolic link already exists.(ansi reset)'
      return
    }
    print $'(ansi yellow)Updating(ansi reset) ($description) — was: ($current_target)'
    if (is-windows) {
      windows-delete-reparse $link_path
    } else {
      ^rm -f $link_path
    }
  }

  if ($link_path | path exists) {
    print $'Removing existing ($description) to replace with symbolic link'
    rm -rf $link_path
  }

  let parent_dir = ($link_path | path dirname)
  if not ($parent_dir | path exists) {
    mkdir $parent_dir
  }

  print $'(ansi green)Creating symbolic link for(ansi reset) ($description)'
  if (is-windows) {
    let t = ($target | str replace --all '/' '\')
    let l = ($link_path | str replace --all '/' '\')
    if ($target | path type) == 'dir' {
      ^cmd /c mklink /j $l $t
    } else {
      ^cmd /c mklink $l $t
    }
  } else {
    ^ln -s $target $link_path
  }
}

# Copies src to dest. Replaces a stale symlink; keeps an existing regular file.
def copy-file [src: string, dest: string, description: string] {
  let exists = ($dest | path exists -n)
  let is_symlink = $exists and (($dest | path type) == 'symlink')

  if $is_symlink {
    print $'(ansi yellow)Replacing stale symlink(ansi reset) for ($description)'
    if (is-windows) {
      windows-delete-reparse $dest
    } else {
      ^rm -f $dest
    }
  } else if $exists {
    print $'($description) (ansi blue)already exists, leaving local copy in place.(ansi reset)'
    return
  }

  let parent_dir = ($dest | path dirname)
  if not ($parent_dir | path exists) {
    mkdir $parent_dir
  }

  print $'(ansi green)Copying(ansi reset) ($description)'
  cp $src $dest
}

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

# Deletes a symlink or junction without touching its target
def windows-delete-reparse [path] {
  let del_script = '(Get-Item -Force -LiteralPath $env:DEL_PATH).Delete()'
  with-env { DEL_PATH: ($path | str replace --all '/' '\') } {
    ^powershell -NoProfile -Command $del_script
  }
}

# True if the current process is running as Administrator
def windows-is-admin [] {
  (^powershell -NoProfile -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" | str trim) == "True"
}

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
  if (windows-is-admin) or (windows-dev-mode-enabled) { return }
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

  if (windows-is-admin) {
    for a in $resolved { allow-cfa-app $a.path $a.name }
    return
  }

  warn 'Controlled Folder Access is enabled. Run in an elevated PowerShell to allow these:'
  for a in $resolved { print $"  Add-MpPreference -ControlledFolderAccessAllowedApplications '($a.path)'" }
}
