$dotfilesRepoDir = "$HOME/stuff/repo/.dotfiles"

function CreateSymbolicLink($linkPath, $targetPath, $description)
{
    if (Test-Path $linkPath)
    {
        Write-Host "$description symbolic link already exists."
    } else
    {
        Write-Host "Creating symbolic link for $description"
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath
    }
}

CreateSymbolicLink "$env:LOCALAPPDATA\nvim" "$dotfilesRepoDir\nvim" "nvim"
CreateSymbolicLink "$HOME\.ideavimrc" "$dotfilesRepoDir\.ideavimrc" ".ideavimrc"
CreateSymbolicLink "$HOME\.wezterm.lua" "$dotfilesRepoDir\.wezterm.lua" ".wezterm.lua"
CreateSymbolicLink "$HOME\.zshrc" "$dotfilesRepoDir\.zshrc" ".zshrc"
CreateSymbolicLink "$env:LOCALAPPDATA\lf\lfrc" "$dotfilesRepoDir\lf\windows\lfrc" "lf (lfrc)"
CreateSymbolicLink "$env:LOCALAPPDATA\lf\icons" "$dotfilesRepoDir\lf\windows\icons" "lf (icons)"

Write-Host "Creating symbolic link for Microsoft.PowerShell_profile.ps1"
if (Test-Path $PROFILE) {
    Remove-Item $PROFILE
}
New-Item -ItemType SymbolicLink -Path $PROFILE -Target "$dotfilesRepoDir\Microsoft.PowerShell_profile.ps1"

Write-Host "Setting environment variable for .ripgreprc"
setx RIPGREP_CONFIG_PATH "$dotfilesRepoDir\.ripgreprc"

