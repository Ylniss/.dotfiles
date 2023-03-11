$repo = "~/Stuff/Repo/"
$games = "C:/Games/"
$dwn = "~/Stuff/Downloads/"

function fnd()
{
    param([string]$path, [string]$dirOrFileName)
    Get-Childitem -Path "$path" -Include *$dirOrFileName* -Recurse -ErrorAction SilentlyContinue
}

function repo()
{
    Set-Location $repo
}

function games()
{
    Set-Location $games
}

function dwn()
{
    Set-Location $dwn
}

function e()
{
	param([string] $path)
	if($path) {
		explorer $path
	} else {
		explorer .
	}

}

function ntpd()
{
    param([string] $path)
    start notepad++ $path
}

function symlink () {
    param([string] $source, [string] $target)
    New-Item -Path $source -ItemType SymbolicLink -Value $target
}

oh-my-posh init pwsh | Invoke-Expression
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile))
{
    Import-Module "$ChocolateyProfile"
}
