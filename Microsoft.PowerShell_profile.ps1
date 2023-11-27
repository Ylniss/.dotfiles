$repoPath = "~/Stuff/Repo/"
$gamesPath = "C:/Games/"
$downloadsPath = "~/Downloads/"

# --------------------------------
#           NAVIGATION
# --------------------------------

function FindDirOrFileName()
{
    param([string]$path, [string]$dirOrFileName)
	Get-Childitem -Path "$path" -Include *$dirOrFileName* -Recurse -ErrorAction SilentlyContinue
}

function ChangeDirToRepo()
{
    Set-Location $repoPath
}

function ChangeDirToGames()
{
    Set-Location $gamesPath
}

function ChangeDirToDownloads()
{
    Set-Location $downloadsPath
}

function OpenExplorer()
{
	param([string] $path)
	if($path) {
		explorer $path
	} else {
		explorer .
	}
}

Set-Alias -Name fnd   -Value FindDirOrFileName
Set-Alias -Name repo  -Value ChangeDirToRepo
Set-Alias -Name games -Value ChangeDirToGames
Set-Alias -Name dwn   -Value ChangeDirToDownloads
Set-Alias -Name e     -Value OpenExplorer


# --------------------------------
#           DEVELOPMENT
# --------------------------------

function OpenWithNotepad()
{
    param([string] $path)
    start notepad++ $path
}

function StartDevTools {
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

# ----- GIT -----

function GitStatus 
{ 
	git status 
}

function GitAddAll 
{ 
	param([string] $path)
	
	if($path) {
		git add $path
	} else {
		git add .
	}
}

function GitDiff {
	
	$gitDiffOutput = git diff

    if (![string]::IsNullOrWhiteSpace($gitDiffOutput))
	{
		Write-Host "Unstaged Changes:" -ForegroundColor Red
		git diff
    } 
	
	$gitDiffStagedOutput = git diff --staged
	
	if (![string]::IsNullOrWhiteSpace($gitDiffStagedOutput))
	{
		Write-Host "Staged Changes:" -ForegroundColor Green
		git diff --staged
    }  
}

function GitCommitMessage 
{ 
	param($message); 
	git commit -m $message 
}

function GitPushOrigin 
{ 
	git push -u origin
}

# ----- DOCKER -----

function DockerComposeUp 
{ 
	docker compose up
}

function DockerComposeUpBuild
{ 
	docker compose up --build
}


Set-Alias -Name ntpd -Value OpenWithNotepad
Set-Alias -Name dev  -Value StartDevTools

Set-Alias -Name gits -Value GitStatus
Set-Alias -Name gita -Value GitAddAll
Set-Alias -Name gitd -Value GitDiff
Set-Alias -Name gitc -Value GitCommitMessage
Set-Alias -Name gitp -Value GitPushOrigin

Set-Alias -Name dckrcu -Value DockerComposeUp
Set-Alias -Name dckrcub -Value DockerComposeUpBuild

# --------------------------------
#             GAMES
# --------------------------------

function StartRa2WithAutoClicker()
{
	$originalPath = Get-Location
	start "$env:ProgramFiles (x86)\Red Alert 2 Blitz Autoclicker\autoclicker.exe"
	Set-Location "$gamesPath\Command and Conquer Red Alert II"
	start CnCNetYRLauncher.exe
	Set-Location $originalPath
}
Set-Alias -Name ra2 -Value StartRa2WithAutoClicker


# --------------------------------
#             SYSTEM
# --------------------------------

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
