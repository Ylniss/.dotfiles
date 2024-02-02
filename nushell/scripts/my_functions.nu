alias repo = cd $env.repo
alias games = cd $env.games
alias dwn = cd $env.downloads

# Make directory and enter inside
def mkdircd --env [dirName: string] {
  mkdir $dirName
  cd $dirName
}

# Change dir with fzf
def fcd --env [] {
  let filePath = fzf
  if ($filePath | path exists) {
    cd ($filePath | path dirname)
  }
}

# Open file in nvim with fzf
def fvi [] {
  nvim (fzf) 
}

# Get weather information for specified city or current location city if not specified
def wthr [city?: string] {
  def skip_lines [lines_to_skip: int] {
    let input = $in
    echo $input | lines | skip $lines_to_skip | each { |it| echo $it }
  }

  def colorize_weather [] {
    let input = $in
    $input | each { |it|
      let line = $it
      # Apply colorization based on weather symbols
      let line = $line | str replace -a "-" $"(ansi yellow)-(ansi reset)" 
      | str replace -a "^" $"(ansi green)^(ansi reset)"
      | str replace -a "=" $"(ansi blue)=(ansi reset)"
      | str replace -a "=V=" $"(ansi red)=V=(ansi reset)"
      | str replace -a "#" $"(ansi magenta)#(ansi reset)"
      | str replace -a "|" $"(ansi cyan)|(ansi reset)"
      | str replace -a "!" $"(ansi blue)!(ansi reset)"
      | str replace -a "*" $"(ansi white)*(ansi reset)"
      echo $line
    }
  }

  let wttr_info = curl -sS wttr.in

  mut current_city = $city
  if $current_city == null {
    $current_city = ($wttr_info | rg "Weather report: ([^,]+)" -Nor "$1")
  }

  finger $'($current_city)@graph.no' | skip_lines 2 | drop 2 | colorize_weather
  echo $wttr_info | skip_lines 1

  null
}

# -------------- SSH -------------- 

# SSH into mobile phone
def 'ssh mob' [] {
  ssh u0_a344@192.168.1.100 -p 8022 -i ~/.ssh/personal 
}

# Copy to clipboard file contents from mobile phone
def 'ssh mob clip' [file_path: string] {
    let clipboard_cmd = if $nu.os_info.family == 'windows' { 'clip' } else { 'pbcopy' }
    ssh u0_a344@192.168.1.100 -p 8022 -i ~/.ssh/personal "cat $file_path" | $clipboard_cmd
}

# -------------- GIT -------------- 

# Git Status: Shows the working tree status.
def gits [] { git status }

# Git Add All: Adds all changes in a specified path, or the current directory if no path is given.
def gita [path?: string] {
  if ($path != null and ($path | path exists)) {
    git add $path 
  } else { 
    git add . 
    } 
}

# Show Git Graph: Displays a graphical representation of the git commit history.
def gitg [] {
  git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD | lines | split column "»¦«" commit message name email date | upsert date {|d| $d.date | into datetime} | sort-by date
}

# Git Diff: Displays unstaged and staged changes with appropriate messages.
def gitd [] {
  let gitDiffOutput = git diff | str join
  if $gitDiffOutput != "" {
    echo $"(ansi red)\n --------------------- Unstaged Changes --------------------- (ansi reset)"
    git diff
  }
  let gitDiffStagedOutput = git diff --staged | str join
  if $gitDiffStagedOutput != "" {
    echo $"(ansi green)\n --------------------- Staged Changes --------------------- (ansi reset)"
    git diff --staged
  }
}

# Git Commit Message: Commits changes with a given commit message.
def gitc [message: string] {
  git commit -m $message 
}

# Git Push Origin: Pushes the current branch to the origin remote, setting upstream if specified.
def gitp [branchName?: string] {
  if $branchName != null and $branchName != "" {
    git push -u origin $branchName 
  } else {
    git push -u origin 
  } 
}

# ------------- DOCKER ------------- 

alias dockercu = docker compose up
alias dockercub = docker compose up --build

# -------------- NVIM -------------- 

alias vi = nvim
alias vim = nvim

# -------------- LF --------------- 

# Change directory into path that lf exits on
def lfcd --env [] {
  let tmp = (mktemp)
  lf -last-dir-path $tmp
  try {
    let target_dir = (open --raw $tmp)
    rm -f $tmp
    try {
      if ($target_dir != $env.PWD) { cd $target_dir }
    } catch { |e| print -e $'lfcd: Can not change to ($target_dir): ($e | get debug)' }
  } catch {
    |e| print -e $'lfcd: Reading ($tmp) returned an error: ($e | get debug)'
  }
}

alias lf = lfcd
