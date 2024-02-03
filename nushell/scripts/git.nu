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

