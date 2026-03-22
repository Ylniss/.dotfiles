alias gits = git status

# Git Add changes in a specified path, or the current directory if no path is given.
def gita --wrapped [path?: string, ...opts] {
  if ((not ($path | is-empty)) and ($path | path exists)) {
    git add ...$opts $path
  } else {
    git add ...$opts .
  }
}

# Show Git Log: Displays a graphical representation of the git commit history.
def gitl [--grph (-g)] {
  if $grph {
    git log --all --decorate --oneline --graph --pretty=format:'%C(auto)%h %<(12,trunc)%an %<(16,trunc)%ar %s %d'
  } else {
    git log $"--pretty=(ansi yellow)%h(ansi reset)»¦«%s»¦«%aN»¦«%aE»¦«%aD" | lines | split column "»¦«" commit message name email date | upsert date {|d| $d.date | into datetime} | sort-by date
  }
}

# Git Diff: Displays unstaged and staged changes with appropriate messages.
def gitd --wrapped [...opts] {
  let gitDiffOutput = git diff
  if $gitDiffOutput != "" {
    print $"(ansi red)\n --------------------- Unstaged Changes --------------------- (ansi reset)"
    git diff ...$opts
  }
  let gitDiffStagedOutput = git diff --staged
  if $gitDiffStagedOutput != "" {
    print $"(ansi green)\n --------------------- Staged Changes --------------------- (ansi reset)"
    git diff --staged ...$opts
  }

  if $gitDiffOutput == "" and $gitDiffStagedOutput == "" {
    git diff ...$opts
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

# Git Push: Pushes to origin, optionally targeting a specific branch.
def gitp --wrapped [branchName?: string, ...opts] {
  if not ($branchName | is-empty) {
    git push origin $branchName ...$opts
  } else {
    git push ...$opts
  }
}

alias gitch = git checkout
alias gitb = git branch
def gitbch [branch: string] {
  git checkout -b $branch
}

def gitmrg [branch: string] {
  let currentBranch = git rev-parse --abbrev-ref HEAD
  git fetch --all

  # Check if the current branch has an upstream set, if not, set it to origin/currentBranch
  if (git rev-parse --abbrev-ref --symbolic-full-name @{u} | is-empty) {
    git branch $'--set-upstream-to=origin/($currentBranch)' $currentBranch
  }

  git merge $"origin/($branch)" --allow-unrelated-histories
}

# Initialize new git repo
def giti [
  repoName?: string # New repo name, if not specified it will be created in current working dir
  --github (-g) # Create repo also on github
] {
  let currentDir = pwd | path basename
  if ($repoName | is-empty) {
    git init

    if $github {
      gh auth login
      gh repo create $currentDir --private --source=.
    }
    touch .gitignore
  } else {
    git init $repoName

    if $github {
      gh auth login
      gh repo create $repoName --private $"--source=(pwd)/($repoName)"
    }
    touch $"(pwd)/($repoName)/.gitignore"
  }
}
