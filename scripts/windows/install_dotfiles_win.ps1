$dotfilesRepoDir = "$HOME/stuff/repo/.dotfiles"

function CreateSymbolicLink($target, $linkPath, $description)
{
    if (Test-Path $linkPath)
    {
        Write-Host "$description symbolic link already exists."
    } else
    {
        Write-Host "Creating symbolic link for $description"
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $target
    }
}

CreateSymbolicLink "$dotfilesRepoDir\nvim" "$env:LOCALAPPDATA\nvim" "nvim"
CreateSymbolicLink "$dotfilesRepoDir\.ideavimrc" "$HOME\.ideavimrc"  ".ideavimrc"
CreateSymbolicLink "$dotfilesRepoDir\.wezterm.lua" "$HOME\.wezterm.lua" ".wezterm.lua"
CreateSymbolicLink "$dotfilesRepoDir\.zshrc" "$HOME\.zshrc" ".zshrc"
CreateSymbolicLink "$dotfilesRepoDir\lf\windows\lfrc" "$env:LOCALAPPDATA\lf\lfrc" "lf (lfrc)"
CreateSymbolicLink "$dotfilesRepoDir\lf\windows\icons" "$env:LOCALAPPDATA\lf\icons" "lf (icons)"
CreateSymbolicLink "$dotfilesRepoDir\starship.toml" "$HOME\.config\starship.toml" "starship.toml"

CreateSymbolicLink "$dotfilesRepoDir\nushell\config.nu" "$env:APPDATA\nushell\config.nu" " nushell config.nu"
CreateSymbolicLink "$dotfilesRepoDir\nushell\env.nu" "$env:APPDATA\nushell\env.nu" "nushell env.nu"
CreateSymbolicLink "$dotfilesRepoDir\nushell\scripts" "$env:APPDATA\nushell\scripts" "nushell scripts"

Write-Host "Creating symbolic link for Microsoft.PowerShell_profile.ps1"
if (Test-Path $PROFILE)
{
    Remove-Item $PROFILE
}
CreateSymbolicLink "$dotfilesRepoDir\Microsoft.PowerShell_profile.ps1" "$PROFILE" "lf (icons)"

Write-Host "Setting environment variable for .ripgreprc"
setx RIPGREP_CONFIG_PATH "$dotfilesRepoDir\.ripgreprc"

