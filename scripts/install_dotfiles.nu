#!/usr/bin/env nu

# -------------- MAIN --------------

let repoDir = (get-dotfiles-repo-dir)

let isWindows = $nu.os-info.family =~ windows
let isAndroid = $nu.os-info.name == 'android'

let homeDir = if $isWindows { $env.USERPROFILE } else { $env.HOME }
let configDir = if $isWindows { $env.LOCALAPPDATA } else { $'($env.HOME)/.config' }
let appdataDir = if $isWindows { $env.APPDATA } else { $'($env.HOME)/.config' }
let yaziConfigDir = if $isWindows { $'($env.APPDATA)/yazi/config' } else { $'($configDir)/yazi' }
let lfSubdir = if $isWindows { 'windows' } else { 'linux' }

let symlinks = [
  { src: 'nvim',                          desc: 'nvim',                       target: $'($configDir)/nvim' }
  { src: '.gitconfig',                    desc: '.gitconfig',                 target: $'($homeDir)/.gitconfig' }
  { src: '.ideavimrc',                    desc: '.ideavimrc',                 target: $'($homeDir)/.ideavimrc',                  skipOnAndroid: true }
  { src: '.wezterm.lua',                  desc: '.wezterm.lua',               target: $'($homeDir)/.wezterm.lua',                skipOnAndroid: true }
  { src: '.zshrc',                        desc: '.zshrc',                     target: $'($homeDir)/.zshrc' }
  { src: $'lf/($lfSubdir)/lfrc',          desc: 'lf (lfrc)',                  target: $'($configDir)/lf/lfrc' }
  { src: $'lf/($lfSubdir)/icons',         desc: 'lf (icons)',                 target: $'($configDir)/lf/icons' }
  { src: 'yazi/yazi.toml',                desc: 'yazi yazi.toml',             target: $'($yaziConfigDir)/yazi.toml' }
  { src: 'yazi/keymap.toml',              desc: 'yazi keymap.toml',           target: $'($yaziConfigDir)/keymap.toml' }
  { src: 'yazi/theme.toml',               desc: 'yazi theme.toml',            target: $'($yaziConfigDir)/theme.toml' }
  { src: 'yazi/package.toml',             desc: 'yazi package.toml',          target: $'($yaziConfigDir)/package.toml' }
  { src: 'yazi/init.lua',                 desc: 'yazi init.lua',              target: $'($yaziConfigDir)/init.lua' }
  { src: 'starship.toml',                 desc: 'starship.toml',              target: $'($homeDir)/.config/starship.toml' }
  { src: 'nushell/config.nu',             desc: 'nushell config.nu',          target: $'($appdataDir)/nushell/config.nu' }
  { src: 'nushell/env.nu',                desc: 'nushell env.nu',             target: $'($appdataDir)/nushell/env.nu' }
  { src: 'nushell/scripts',               desc: 'nushell scripts',            target: $'($appdataDir)/nushell/scripts' }
  { src: 'claude/CLAUDE.md',              desc: 'claude CLAUDE.md',           target: $'($homeDir)/.claude/CLAUDE.md' }
  { src: 'claude/settings.json',          desc: 'claude settings.json',       target: $'($homeDir)/.claude/settings.json' }
  { src: 'claude/statusline-command.sh',  desc: 'claude statusline-command.sh', target: $'($homeDir)/.claude/statusline-command.sh' }
  { src: 'claude/skills',                 desc: 'claude skills',              target: $'($homeDir)/.claude/skills' }
  { src: 'claude/agents',                 desc: 'claude agents',              target: $'($homeDir)/.claude/agents' }
]

if $isWindows { windows-require-symlink-capability }

$symlinks
  | where { |s| not (($s.skipOnAndroid? | default false) and $isAndroid) }
  | each { |s| create-symbolic-link $'($repoDir)/($s.src)' $s.target $s.desc }
  | ignore

install-yazi-packages

ensure-gitconfig-local $homeDir

if $isWindows { allow-cfa-apps-if-needed }

# -------------- FUNCTIONS --------------

# Returns the dotfiles repo directory for this platform
def get-dotfiles-repo-dir [] {
  if $nu.os-info.family =~ windows {
    $'($env.USERPROFILE)/stuff/repo/.dotfiles'
  } else {
    $'($env.HOME)/stuff/repo/.dotfiles'
  }
}

# Creates a symlink, replacing existing file/dir; on Windows clears stale ancestor reparse points first
def create-symbolic-link [target, linkPath, description] {
  # Remove any ancestor reparse point first so rm/mkdir below don't follow it
  # into its target.
  if ($nu.os-info.family =~ windows) {
    mut anc = ($linkPath | path dirname)
    mut stale = ''
    loop {
      if ($anc | path exists -n) and (windows-is-reparse-point $anc) {
        $stale = $anc
        break
      }
      let up = ($anc | path dirname)
      if $up == $anc { break }
      $anc = $up
    }
    if ($stale | is-not-empty) {
      print $'Removing stale directory symlink before linking ($description): ($stale)'
      let delScript = '(Get-Item -Force -LiteralPath $env:DEL_PATH).Delete()'
      with-env { DEL_PATH: ($stale | str replace --all '/' '\') } {
        ^powershell -NoProfile -Command $delScript
      }
    }
  }

  let isSymlink = if ($nu.os-info.family =~ windows) {
    ($linkPath | path exists) and ($linkPath | path type) == 'symlink'
  } else {
    (do { ^test -L $linkPath } | complete).exit_code == 0
  }

  if $isSymlink {
    print $'($description) symbolic link already exists.'
    return
  }

  if ($linkPath | path exists) {
    print $'Removing existing ($description) to replace with symbolic link'
    rm -rf $linkPath
  }

  let parentDir = ($linkPath | path dirname)
  if not ($parentDir | path exists) {
    mkdir $parentDir
  }

  print $'Creating symbolic link for ($description)'
  if ($nu.os-info.family =~ windows) {
    let t = ($target | str replace --all '/' '\')
    let l = ($linkPath | str replace --all '/' '\')
    if ($target | path type) == 'dir' {
      ^cmd /c $"mklink /j ($l) ($t)"
    } else {
      ^cmd /c $"mklink ($l) ($t)"
    }
  } else {
    ^ln -s $target $linkPath
  }
}

# Installs yazi plugins via `ya pkg install` (no-op if `ya` is missing)
def install-yazi-packages [] {
  if (which ya | is-empty) {
    print 'ya CLI not found on PATH. Skipping yazi plugin install — install yazi, then rerun this script (or run `ya pkg install`).'
    return
  }
  print 'Installing yazi plugins via `ya pkg install`'
  try {
    ^ya pkg install
  } catch { |e|
    print -e $'ya pkg install failed: ($e.msg)'
  }
}

# Creates ~/.gitconfig-local with the default user info if it doesn't exist
def ensure-gitconfig-local [homeDir] {
  let gitconfigLocal = $'($homeDir)/.gitconfig-local'
  if ($gitconfigLocal | path exists) { return }
  print 'Creating .gitconfig-local with default user'
  "[user]\n\tname = Ylniss\n\temail = zupqa0@gmail.com\n" | save $gitconfigLocal
}

# -------------- WINDOWS --------------

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
  (^powershell -NoProfile -Command "(Get-MpPreference).EnableControlledFolderAccess" | str trim) != "0"
}

# True if path is a symlink or junction (reparse point)
def windows-is-reparse-point [path] {
  if not ($path | path exists -n) { return false }
  let script = 'try { (Get-Item -Force -LiteralPath $env:CHECK_PATH -ErrorAction Stop).Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint) } catch { "False" }'
  let r = (with-env { CHECK_PATH: ($path | str replace --all '/' '\') } {
    ^powershell -NoProfile -Command $script | complete
  })
  ($r.stdout | str trim) == "True"
}

# Errors out unless admin or Developer Mode is enabled
def windows-require-symlink-capability [] {
  if (windows-is-admin) or (windows-dev-mode-enabled) { return }
  error make { msg: "Cannot create symbolic links. Enable Developer Mode (Settings > System > For developers) or run this script as Administrator." }
}

# Adds one executable to the Defender CFA allow-list
def allow-cfa-app [exePath, appName] {
  ^powershell -NoProfile -Command $"Add-MpPreference -ControlledFolderAccessAllowedApplications '($exePath)'"
  print $'Allowed ($appName) through Controlled Folder Access'
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
    $resolved | each { |a| allow-cfa-app $a.path $a.name } | ignore
    return
  }

  print 'Controlled Folder Access is enabled. Run in an elevated PowerShell to allow these:'
  $resolved | each { |a| print $"  Add-MpPreference -ControlledFolderAccessAllowedApplications '($a.path)'" } | ignore
}
