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
    echo $"(ansi red)\n --------------------- Unstaged Changes --------------------- (ansi reset)"
    git diff ...$opts
  }
  let gitDiffStagedOutput = git diff --staged
  if $gitDiffStagedOutput != "" {
    echo $"(ansi green)\n --------------------- Staged Changes --------------------- (ansi reset)"
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

# Git Push Origin: Pushes the current branch to the origin remote, setting upstream if specified.
def gitp --wrapped [branchName?: string, ...opts] {
  let currentBranch = git rev-parse --abbrev-ref HEAD

  def git-push [] {
    if not ($branchName | is-empty) {
      git push -u origin $branchName ...$opts
    } else {
      git push -u origin $currentBranch ...$opts
    } 
  }
  
  # Check if the current branch has an upstream set
  let res = do -i { git rev-parse --abbrev-ref @{upstream} } | complete
  let upstream = $res.stderr | is-empty 

  if $upstream == false {
    # If there's no upstream, set it automatically
    let resGitBranch = do { git branch $"--set-upstream-to=origin/($currentBranch)" $currentBranch } | complete
    let noBranch = not ($resGitBranch.stderr | is-empty)
    if $noBranch {
      git-push     
    }

    echo $"Upstream set to origin/($currentBranch) for branch ($currentBranch)."
    git pull origin $currentBranch --allow-unrelated-histories
  }

  git-push
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
  print "currentdir: " $currentDir
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
