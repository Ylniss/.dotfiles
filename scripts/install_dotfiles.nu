#!/usr/bin/env nu

let dotfilesRepoDir = if $nu.os-info.family =~ windows {
  $'($env.USERPROFILE)/stuff/repo/.dotfiles'
} else {
  $'($env.HOME)/stuff/repo/.dotfiles'
}

def create-symbolic-link [target, linkPath, description] {
  if ($linkPath | path exists) or (not ($nu.os-info.family =~ windows) and ((do { ^test -L $linkPath } | complete).exit_code == 0)) {
    print $'($description) symbolic link already exists.'
  } else {

    let parentDir = ($linkPath | path dirname)
    if (not ($parentDir | path exists)) {
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
  create-symbolic-link $'($dotfilesRepoDir)\starship.toml' $'($env.USERPROFILE)\.config\starship.toml' 'starship.toml'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\config.nu' $'($env.APPDATA)\nushell\config.nu' 'nushell config.nu'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\env.nu' $'($env.APPDATA)\nushell\env.nu' 'nushell env.nu'
  create-symbolic-link $'($dotfilesRepoDir)\nushell\scripts' $'($env.APPDATA)\nushell\scripts' 'nushell scripts'
  create-symbolic-link $'($dotfilesRepoDir)\claude\CLAUDE.md' $'($env.USERPROFILE)\.claude\CLAUDE.md' 'claude CLAUDE.md'
  create-symbolic-link $'($dotfilesRepoDir)\claude\settings.json' $'($env.USERPROFILE)\.claude\settings.json' 'claude settings.json'
  create-symbolic-link $'($dotfilesRepoDir)\claude\skills' $'($env.USERPROFILE)\.claude\skills' 'claude skills'
  create-symbolic-link $'($dotfilesRepoDir)\claude\agents' $'($env.USERPROFILE)\.claude\agents' 'claude agents'
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
  create-symbolic-link $'($dotfilesRepoDir)/starship.toml' $'($env.HOME)/.config/starship.toml' 'starship.toml'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/config.nu' $'($env.HOME)/.config/nushell/config.nu' 'nushell config.nu'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/env.nu' $'($env.HOME)/.config/nushell/env.nu' 'nushell env.nu'
  create-symbolic-link $'($dotfilesRepoDir)/nushell/scripts' $'($env.HOME)/.config/nushell/scripts' 'nushell scripts'
  create-symbolic-link $'($dotfilesRepoDir)/claude/CLAUDE.md' $'($env.HOME)/.claude/CLAUDE.md' 'claude CLAUDE.md'
  create-symbolic-link $'($dotfilesRepoDir)/claude/settings.json' $'($env.HOME)/.claude/settings.json' 'claude settings.json'
  create-symbolic-link $'($dotfilesRepoDir)/claude/skills' $'($env.HOME)/.claude/skills' 'claude skills'
  create-symbolic-link $'($dotfilesRepoDir)/claude/agents' $'($env.HOME)/.claude/agents' 'claude agents'
}
