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

function cnc()
{
	$originalPath = Get-Location
	start "$env:ProgramFiles (x86)\Red Alert 2 Blitz Autoclicker\autoclicker.exe"
	Set-Location "$games\Command and Conquer Red Alert II"
	start CnCNetYRLauncher.exe
	Set-Location $originalPath
}

function dev {
    param (
        [switch]$f
    )

    $riderPath = Get-ChildItem -Path "$env:ProgramFiles\JetBrains\*Rider *\bin\rider*.exe" -File | Select-Object -First 1 -ExpandProperty FullName
    $dataGripPath = Get-ChildItem -Path "$env:ProgramFiles (x86)\JetBrains\*DataGrip *\bin\datagrip*.exe" -File | Select-Object -First 1 -ExpandProperty FullName
	$webStormPath = Get-ChildItem -Path "$env:ProgramFiles (x86)\JetBrains\*WebStorm *\bin\webstorm*.exe" -File | Select-Object -First 1 -ExpandProperty FullName
    
    $dockerDesktopPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    $githubDesktopPath = "~\AppData\Local\GitHubDesktop\GitHubDesktop.exe"
    $postmanPath = "~\AppData\Local\Postman\Postman.exe"

    foreach ($app in @(
        @{Path = $riderPath; Name = "JetBrains Rider"},
        @{Path = $dataGripPath; Name = "JetBrains DataGrip"},
        @{Path = $dockerDesktopPath; Name = "Docker Desktop"},
        @{Path = $githubDesktopPath; Name = "GitHub Desktop"},
        @{Path = $postmanPath; Name = "Postman"}
    )) {
        if ($app.Path -and (Test-Path $app.Path)) {
            start $app.Path
        } else {
            Write-Host "$($app.Name) not found at $($app.Path)"
        }
    }

    if ($f -and $webStormPath -and (Test-Path $webStormPath)) {
        start $webStormPath
    } elseif ($f) {
        Write-Host "JetBrains WebStorm not found."
    }
}

function symlink () {
    param([string] $source, [string] $target)
    New-Item -Path $source -ItemType SymbolicLink -Value $target
}

oh-my-posh init pwsh | Invoke-Expression

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile))
{
    Import-Module "$ChocolateyProfile"
}
