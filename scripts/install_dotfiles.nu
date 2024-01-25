#!/usr/bin/env nu

let dotfilesRepoDir = if $nu.os-info.family =~ windows {
  "$env.USERPROFILE/stuff/repo/.dotfiles" 
} else {
  "$env.HOME/stuff/repo/.dotfiles" 
}

def create-symbolic-link [target, linkPath, description] {
    if ($linkPath | path exists) {
        echo "$description symbolic link already exists."
    } else {
        echo "Creating symbolic link for $description"
        if ($nu.os-info.family =~ windows) {
            sys New-Item -ItemType SymbolicLink -Path $linkPath -Target $target
        } else {
            sys ln -s $target $linkPath
        }
    }
}

if ($nu.os-info.family =~ windows) {
    create-symbolic-link "$dotfilesRepoDir\nvim" "$env.LOCALAPPDATA\nvim" "nvim"
    create-symbolic-link "$dotfilesRepoDir\.ideavimrc" "$env.USERPROFILE\.ideavimrc" ".ideavimrc"
    create-symbolic-link "$dotfilesRepoDir\.wezterm.lua" "$env.USERPROFILE\.wezterm.lua" ".wezterm.lua"
    create-symbolic-link "$dotfilesRepoDir\.zshrc" "$env.USERPROFILE\.zshrc" ".zshrc"
    create-symbolic-link "$dotfilesRepoDir\lf\windows\lfrc" "$env.LOCALAPPDATA\lf\lfrc" "lf (lfrc)"
    create-symbolic-link "$dotfilesRepoDir\lf\windows\icons" "$env.LOCALAPPDATA\lf\icons" "lf (icons)"
    create-symbolic-link "$dotfilesRepoDir\starship.toml" "$env.USERPROFILE\.config\starship.toml" "starship.toml"
    create-symbolic-link "$dotfilesRepoDir\nushell\config.nu" "$env.APPDATA\nushell\config.nu" "nushell config.nu"
    create-symbolic-link "$dotfilesRepoDir\nushell\env.nu" "$env.APPDATA\nushell\env.nu" "nushell env.nu"
    create-symbolic-link "$dotfilesRepoDir\nushell\scripts" "$env.APPDATA\nushell\scripts" "nushell scripts"

    setx RIPGREP_CONFIG_PATH "$dotfilesRepoDir\.ripgreprc"
} else {
    # For Linux/Android
    create-symbolic-link "$dotfilesRepoDir/nvim" "$env.HOME/.config/nvim" "nvim"
    create-symbolic-link "$dotfilesRepoDir/.ideavimrc" "$env.HOME/.ideavimrc" ".ideavimrc"
    create-symbolic-link "$dotfilesRepoDir/.wezterm.lua" "$env.HOME/.wezterm.lua" ".wezterm.lua"
    create-symbolic-link "$dotfilesRepoDir/.zshrc" "$env.HOME/.zshrc" ".zshrc"
    create-symbolic-link "$dotfilesRepoDir/lf/linux/lfrc" "$env.HOME/.config/lf/lfrc" "lf (lfrc)"
    create-symbolic-link "$dotfilesRepoDir/lf/linux/icons" "$env.HOME/.config/lf/icons" "lf (icons)"
    create-symbolic-link "$dotfilesRepoDir/starship.toml" "$env.HOME/.config/starship.toml" "starship.toml"
    create-symbolic-link "$dotfilesRepoDir/nushell/config.nu" "$env.HOME/.config/nushell/config.nu" "nushell config.nu"
    create-symbolic-link "$dotfilesRepoDir/nushell/env.nu" "$env.HOME/.config/nushell/env.nu" "nushell env.nu"
    create-symbolic-link "$dotfilesRepoDir/nushell/scripts" "$env.HOME/.config/nushell/scripts" "nushell scripts"

    export RIPGREP_CONFIG_PATH="$dotfilesRepoDir/.ripgreprc"
}

