$repoPath = "~/Stuff/Repo/"
$gamesPath = "C:/Games/"
$downloadsPath = "~/Downloads/"

# --------------------------------
#           NAVIGATION
# --------------------------------

function FindDirOrFileName() {
    param([string]$path, [string]$dirOrFileName)
	Get-Childitem -Path "$path" -Include *$dirOrFileName* -Recurse -ErrorAction SilentlyContinue
}

function ChangeDirToRepo() {
    Set-Location $repoPath
}

function ChangeDirToGames() {
    Set-Location $gamesPath
}

function ChangeDirToDownloads() {
    Set-Location $downloadsPath
}

function NewDirectoryAndEnter {
    param([string]$dirName)

    $newPath = Join-Path -Path (Get-Location) -ChildPath $dirName
    New-Item -Path $newPath -ItemType Directory -Force

    Set-Location -Path $newPath
}

function OpenExplorer() {
	param([string] $path)
	if($path) {
		explorer $path
	} else {
		explorer .
	}
}



Set-Alias -Name fnd   -Value FindDirOrFileName

Set-Alias -Name repo  	-Value ChangeDirToRepo
Set-Alias -Name games 	-Value ChangeDirToGames
Set-Alias -Name dwn   	-Value ChangeDirToDownloads
Set-Alias -Name mkdircd -Value NewDirectoryAndEnter

Set-Alias -Name e	-Value OpenExplorer


# --------------------------------
#           DEVELOPMENT
# --------------------------------

function OpenWithNotepad() {
    param([string] $path)
    start notepad++ $path
}

function StartDevTools {
    param ([switch]$f) # start WebStorm for frontend development

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

function GitStatus { 
	git status 
}

function GitAddAll { 
	param([string] $path)
	
	if($path) {
		git add $path
	} else {
		git add .
	}
}

function GitDiff {
	$gitDiffOutput = git diff

    if (![string]::IsNullOrWhiteSpace($gitDiffOutput)) {
		Write-Host "Unstaged Changes:" -ForegroundColor Red
		git diff
    } 
	
	$gitDiffStagedOutput = git diff --staged
	
	if (![string]::IsNullOrWhiteSpace($gitDiffStagedOutput)) {
		Write-Host "Staged Changes:" -ForegroundColor Green
		git diff --staged
    }  
}

function GitCommitMessage { 
	param($message); 
	git commit -m $message 
}

function GitPushOrigin { 
	git push -u origin
}

function GitBranch { 
    param(
        [Parameter(Mandatory=$false)] [string]$newBranchName,
        [Parameter(Mandatory=$false)] [switch]$a, # list all branches
        [Parameter(Mandatory=$false)] [switch]$d, # delete branch
		[Parameter(Mandatory=$false)] [string]$branchNameToDelete
    )

    if ($a) {
        git branch -a
    }
    elseif ($d -and $branchNameToDelete) {
        git branch -d $branchNameToDelete
    }
	elseif ($newBranchName) {
		git branch $newBranchName
	}
    else {
        Write-Host "Please specify an operation or a new branch name."
    }
}

function GitCheckout {
    param($branchName); 
    git checkout $branchName
}

function GitBranchCheckout {
    param($newBranchName); 
	git branch $newBranchName
    git checkout $newBranchName
}

# ----- DOCKER -----

function DockerComposeUp { 
	docker compose up
}

function DockerComposeUpBuild { 
	docker compose up --build
}

Set-Alias -Name ntpd -Value OpenWithNotepad
Set-Alias -Name dev  -Value StartDevTools

Set-Alias -Name gits -Value GitStatus
Set-Alias -Name gita -Value GitAddAll
Set-Alias -Name gitd -Value GitDiff
Set-Alias -Name gitc -Value GitCommitMessage
Set-Alias -Name gitp -Value GitPushOrigin
Set-Alias -Name gitb -Value GitBranch
Set-Alias -Name gitch -Value GitCheckout
Set-Alias -Name gitbch -Value GitBranchCheckout

Set-Alias -Name dckrcu  -Value DockerComposeUp
Set-Alias -Name dckrcub -Value DockerComposeUpBuild


# --------------------------------
#             GAMES
# --------------------------------

function StartRa2WithAutoClicker() {
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
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
