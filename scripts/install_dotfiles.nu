#!/usr/bin/env nu

let dotfilesRepoDir = if $nu.os-info.family =~ windows {
  $'($env.USERPROFILE)/stuff/repo/.dotfiles'
} else {
  $'($env.HOME)/stuff/repo/.dotfiles'
}

def windows-is-admin [] {
  (^powershell -NoProfile -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" | str trim) == "True"
}

def windows-cfa-enabled [] {
  (^powershell -NoProfile -Command "(Get-MpPreference).EnableControlledFolderAccess" | str trim) != "0"
}

def allow-cfa-app [exePath, appName] {
  ^powershell -NoProfile -Command $"Add-MpPreference -ControlledFolderAccessAllowedApplications '($exePath)'"
  print $'Allowed ($appName) through Controlled Folder Access'
}

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

def create-symbolic-link [target, linkPath, description] {
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

if ($nu.os-info.family =~ windows) {
  # Test if we can create symlinks (requires admin or Developer Mode)
  let testLink = $'($env.TEMP)\dotfiles_symlink_test'
  let testTarget = $'($env.TEMP)\dotfiles_symlink_target'
  "test" | save -f $testTarget
  try {
    ^cmd /c $"mklink ($testLink | str replace --all '/' '\') ($testTarget | str replace --all '/' '\')" | ignore
  }
  if not ($testLink | path exists) or (($testLink | path type) != 'symlink') {
    rm -f $testTarget
    error make { msg: "Cannot create symbolic links. Enable Developer Mode: Windows Settings > System > Advanced > Developer Mode." }
  }
  rm -f $testLink $testTarget

  create-symbolic-link $'($dotfilesRepoDir)\nvim' $'($env.LOCALAPPDATA)\nvim' 'nvim'
  create-symbolic-link $'($dotfilesRepoDir)\.gitconfig' $'($env.USERPROFILE)\.gitconfig' '.gitconfig'
  create-symbolic-link $'($dotfilesRepoDir)\.ideavimrc' $'($env.USERPROFILE)\.ideavimrc' '.ideavimrc'
  create-symbolic-link $'($dotfilesRepoDir)\.wezterm.lua' $'($env.USERPROFILE)\.wezterm.lua' '.wezterm.lua'
  create-symbolic-link $'($dotfilesRepoDir)\.zshrc' $'($env.USERPROFILE)\.zshrc' '.zshrc'
  create-symbolic-link $'($dotfilesRepoDir)\lf\windows\lfrc' $'($env.LOCALAPPDATA)\lf\lfrc' 'lf (lfrc)'
  create-symbolic-link $'($dotfilesRepoDir)\lf\windows\icons' $'($env.LOCALAPPDATA)\lf\icons' 'lf (icons)'
  create-symbolic-link $'($dotfilesRepoDir)\yazi\yazi.toml' $'($env.APPDATA)\yazi\config\yazi.toml' 'yazi yazi.toml'
  create-symbolic-link $'($dotfilesRepoDir)\yazi\keymap.toml' $'($env.APPDATA)\yazi\config\keymap.toml' 'yazi keymap.toml'
  create-symbolic-link $'($dotfilesRepoDir)\yazi\theme.toml' $'($env.APPDATA)\yazi\config\theme.toml' 'yazi theme.toml'
  create-symbolic-link $'($dotfilesRepoDir)\yazi\package.toml' $'($env.APPDATA)\yazi\config\package.toml' 'yazi package.toml'
  install-yazi-packages
  create-symbolic-link $'($dotfilesRepoDir)\starship.toml' $'($env.USERPROFILE)\.config\starship.toml' 'starship.toml'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\config.nu' $'($env.APPDATA)\nushell\config.nu' 'nushell config.nu'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\env.nu' $'($env.APPDATA)\nushell\env.nu' 'nushell env.nu'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\scripts' $'($env.APPDATA)\nushell\scripts' 'nushell scripts'
  create-symbolic-link $'($dotfilesRepoDir)\claude\CLAUDE.md' $'($env.USERPROFILE)\.claude\CLAUDE.md' 'claude CLAUDE.md'
  create-symbolic-link $'($dotfilesRepoDir)\claude\settings.json' $'($env.USERPROFILE)\.claude\settings.json' 'claude settings.json'
  create-symbolic-link $'($dotfilesRepoDir)\claude\statusline-command.sh' $'($env.USERPROFILE)\.claude\statusline-command.sh' 'claude statusline-command.sh'
  create-symbolic-link $'($dotfilesRepoDir)\claude\skills' $'($env.USERPROFILE)\.claude\skills' 'claude skills'
  create-symbolic-link $'($dotfilesRepoDir)\claude\agents' $'($env.USERPROFILE)\.claude\agents' 'claude agents'

  let gitconfigLocal = $'($env.USERPROFILE)\.gitconfig-local'
  if not ($gitconfigLocal | path exists) {
    print 'Creating .gitconfig-local with default user'
    "[user]\n\tname = Ylniss\n\temail = zupqa0@gmail.com\n" | save $gitconfigLocal
  }

  # Allow tools through Windows Defender Controlled Folder Access so they can
  # delete files in protected folders (Pictures, Documents, etc.)
  if (windows-cfa-enabled) {
    let apps = [
      { name: 'yazi', cmd: 'yazi' }
      { name: 'nushell', cmd: 'nu' }
    ]
    let resolved = $apps | each { |a|
      let r = (which $a.cmd)
      if ($r | is-empty) { null } else { { name: $a.name, path: ($r | get 0.path) } }
    } | compact

    if ($resolved | is-empty) {
      # nothing on PATH to allow
    } else if (windows-is-admin) {
      $resolved | each { |a| allow-cfa-app $a.path $a.name } | ignore
    } else {
      print 'Controlled Folder Access is enabled. Run in an elevated PowerShell to allow these:'
      $resolved | each { |a| print $"  Add-MpPreference -ControlledFolderAccessAllowedApplications '($a.path)'" } | ignore
    }
  }
} else {
  # For Linux/Android
  create-symbolic-link $'($dotfilesRepoDir)/nvim' $'($env.HOME)/.config/nvim' 'nvim'
  create-symbolic-link $'($dotfilesRepoDir)/.gitconfig' $'($env.HOME)/.gitconfig' '.gitconfig'
  if $nu.os-info.name != 'android' {
    create-symbolic-link $'($dotfilesRepoDir)/.ideavimrc' $'($env.HOME)/.ideavimrc' '.ideavimrc'
    create-symbolic-link $'($dotfilesRepoDir)/.wezterm.lua' $'($env.HOME)/.wezterm.lua' '.wezterm.lua'
  }
  create-symbolic-link $'($dotfilesRepoDir)/.zshrc' $'($env.HOME)/.zshrc' '.zshrc'
  create-symbolic-link $'($dotfilesRepoDir)/lf/linux/lfrc' $'($env.HOME)/.config/lf/lfrc' 'lf (lfrc)'
  create-symbolic-link $'($dotfilesRepoDir)/lf/linux/icons' $'($env.HOME)/.config/lf/icons' 'lf (icons)'
  create-symbolic-link $'($dotfilesRepoDir)/yazi/yazi.toml' $'($env.HOME)/.config/yazi/yazi.toml' 'yazi yazi.toml'
  create-symbolic-link $'($dotfilesRepoDir)/yazi/keymap.toml' $'($env.HOME)/.config/yazi/keymap.toml' 'yazi keymap.toml'
  create-symbolic-link $'($dotfilesRepoDir)/yazi/theme.toml' $'($env.HOME)/.config/yazi/theme.toml' 'yazi theme.toml'
  create-symbolic-link $'($dotfilesRepoDir)/yazi/package.toml' $'($env.HOME)/.config/yazi/package.toml' 'yazi package.toml'
  install-yazi-packages
  create-symbolic-link $'($dotfilesRepoDir)/starship.toml' $'($env.HOME)/.config/starship.toml' 'starship.toml'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/config.nu' $'($env.HOME)/.config/nushell/config.nu' 'nushell config.nu'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/env.nu' $'($env.HOME)/.config/nushell/env.nu' 'nushell env.nu'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/scripts' $'($env.HOME)/.config/nushell/scripts' 'nushell scripts'
  create-symbolic-link $'($dotfilesRepoDir)/claude/CLAUDE.md' $'($env.HOME)/.claude/CLAUDE.md' 'claude CLAUDE.md'
  create-symbolic-link $'($dotfilesRepoDir)/claude/settings.json' $'($env.HOME)/.claude/settings.json' 'claude settings.json'
  create-symbolic-link $'($dotfilesRepoDir)/claude/statusline-command.sh' $'($env.HOME)/.claude/statusline-command.sh' 'claude statusline-command.sh'
  create-symbolic-link $'($dotfilesRepoDir)/claude/skills' $'($env.HOME)/.claude/skills' 'claude skills'
  create-symbolic-link $'($dotfilesRepoDir)/claude/agents' $'($env.HOME)/.claude/agents' 'claude agents'

  let gitconfigLocal = $'($env.HOME)/.gitconfig-local'
  if not ($gitconfigLocal | path exists) {
    print 'Creating .gitconfig-local with default user'
    "[user]\n\tname = Ylniss\n\temail = zupqa0@gmail.com\n" | save $gitconfigLocal
  }
}
