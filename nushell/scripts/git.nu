# Git Status: Shows the working tree status.
# def gits --wrapped [...opts] { git status ...$opts }
alias gits = git status

# Git Add All: Adds all changes in a specified path, or the current directory if no path is given.
def gita --wrapped [path?: string, ...opts] {
  if ((not ($path | is-empty)) and ($path | path exists)) {
    git add ...$opts $path  
  } else { 
    git add ...$opts .
  } 
}

# Show Git Log: Displays a graphical representation of the git commit history.
def gitl [] {
  git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD | lines | split column "»¦«" commit message name email date | upsert date {|d| $d.date | into datetime} | sort-by date
}

# Git Diff: Displays unstaged and staged changes with appropriate messages.
def gitd --wrapped [...opts] {
  let gitDiffOutput = git diff
  if $gitDiffOutput != "" {
    echo $"(ansi red)\n --------------------- Unstaged Changes --------------------- (ansi reset)"
    git diff ...$opts
  }
  let gitDiffStagedOutput = git diff --staged
  if $gitDiffStagedOutput != "" {
    echo $"(ansi green)\n --------------------- Staged Changes --------------------- (ansi reset)"
    git diff --staged ...$opts
  }
}

# Git Commit Message: Commits changes with a given commit message.
def gitc --wrapped [...opts, message?: string] {
  if not ($message | is-empty) {
    git commit ...$opts -m $message 
  } else {
    git commit ...$opts
  }
}

# Git Push Origin: Pushes the current branch to the origin remote, setting upstream if specified.
def gitp [branchName?: string, ...opts] {
  if not ($branchName | is-empty) {
    git push -u origin $branchName ...$opts
  } else {
    git push -u origin ...$opts 
  } 
}

