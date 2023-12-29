$dotfilesRepoDir = "$HOME/stuff/repo/.dotfiles"

Write-Host "Creating symbolic link for nvim"
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\nvim" -Target "$dotfilesRepoDir\nvim"

Write-Host "Creating symbolic link for .ideavimrc"
New-Item -ItemType SymbolicLink -Path "$HOME\.ideavimrc" -Target "$dotfilesRepoDir\.ideavimrc"

Write-Host "Creating symbolic link for .wezterm.lua"
New-Item -ItemType SymbolicLink -Path "$HOME\.wezterm.lua" -Target "$dotfilesRepoDir\.wezterm.lua"

Write-Host "Creating symbolic link for .zshrc"
New-Item -ItemType SymbolicLink -Path "$HOME\.zshrc" -Target "$dotfilesRepoDir\.zshrc"

Write-Host "Creating symbolic link for Microsoft.PowerShell_profile.ps1"
if (Test-Path $PROFILE) {
    Remove-Item $PROFILE
}
New-Item -ItemType SymbolicLink -Path $PROFILE -Target "$dotfilesRepoDir\Microsoft.PowerShell_profile.ps1"

Write-Host "Setting environment variable for .ripgreprc"
setx RIPGREP_CONFIG_PATH "$dotfilesRepoDir\.ripgreprc"

Write-Host "Creating symbolic link for lf"
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\lf\lfrc" -Target "$dotfilesRepoDir\lf\windows\lfrc"
