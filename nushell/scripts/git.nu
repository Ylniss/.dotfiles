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
    git log --reverse $"--pretty=(ansi yellow)%h(ansi reset)»¦«%s»¦«%aN»¦«%as" | lines | split column "»¦«" commit message name date | upsert message {|r| $r.message | str substring 0..65} | sort-by date
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

# Git Worktree Add: Creates a new worktree with a new branch.
# Usage: gitwta <branch> — creates worktree at ../{current_dir}-{branch}
def --env gitwta [branch: string, --stay (-s)] {
  let dir_name = (pwd | path basename)
  let path = $"../($dir_name)-($branch)"
  git worktree add $path -b $branch
  if not $stay {
    cd $path
    if 'WEZTERM_PANE' in $env {
      layout-dev
    }
  }
}

# Git Worktree Finish: Pushes branch, merges into base branch, then removes worktree.
# Usage: gitwtf <path> | gitwtf .
def --env gitwtf [path: string] {
  let resolved = if $path == "." { pwd } else { $path | path expand }

  # Validate: is a git repo and get branch
  let branch = try { git -C $resolved rev-parse --abbrev-ref HEAD | str trim } catch {
    print $"(ansi red)Not a git repository(ansi reset)"
    return
  }

  # Get main worktree (base repo) path — always first in porcelain output
  let base_path = (git -C $resolved worktree list --porcelain
    | lines
    | where {|l| $l starts-with 'worktree '}
    | first
    | str replace 'worktree ' '')

  # Validate: not the main worktree
  if ($resolved | path expand | str downcase) == ($base_path | str downcase) {
    print $"(ansi red)This is the main worktree — refusing to remove(ansi reset)"
    return
  }

  # Validate: base repo exists
  if not ($base_path | path exists) {
    print $"(ansi red)Base repo not found at ($base_path)(ansi reset)"
    return
  }

  # Safety: abort if working tree is dirty
  let dirty = (git -C $resolved status --porcelain | str trim)
  if ($dirty | is-not-empty) {
    print $"(ansi red)Uncommitted changes — commit first(ansi reset)"
    return
  }

  # Push worktree branch, merge into base branch, push
  let base_branch = (git -C $base_path rev-parse --abbrev-ref HEAD | str trim)
  try {
    git -C $resolved push origin $branch
    git -C $resolved fetch origin
    git -C $resolved merge $"origin/($base_branch)"
    git -C $resolved push origin $"HEAD:($base_branch)"
  } catch {
    print $"(ansi red)Push/merge failed — resolve and retry(ansi reset)"
    return
  }

  # cd out before removal (only for `.`)
  if $path == "." {
    cd $base_path
  }

  # Pull latest into base repo
  try { git -C $base_path pull } catch {}

  # Remove directory (retry once for Windows handle release)
  if ($resolved | path exists) {
    try { rm -rf $resolved } catch {
      sleep 1sec
      try { rm -rf $resolved } catch {
        print $"(ansi yellow)Warning: could not remove directory — remove it manually(ansi reset)"
      }
    }
  }

  # Clean up git state
  git -C $base_path worktree prune
  try { git -C $base_path branch -D $branch } catch {}
}

# Git Parents: Shows the parent branch chain with ahead/behind counts.
# Walks first-parent history to determine which branch was created from which.
# Example output:
#   ╭───┬──────────────────┬───────┬────────╮
#   │ # │      branch      │ ahead │ behind │
#   ├───┼──────────────────┼───────┼────────┤
#   │ 0 │ feature-x        │     3 │      5 │
#   │ 1 │ ← develop        │    12 │      0 │
#   │ 2 │   ← main         │       │        │
#   ╰───┴──────────────────┴───────┴────────╯
#   ahead  = commits on feature-x not in develop (your work since branching)
#   behind = commits on develop not in feature-x (new work on develop you haven't pulled)
def gitpar [] {
  let all = (git branch --format='%(refname:short)' | lines | str trim)
  mut current = (git rev-parse --abbrev-ref HEAD | str trim)
  mut chain = [$current]

  loop {
    if $current in ['main', 'master'] { break }
    let cur = $current
    let seen = $chain

    let sha = (git rev-parse $"refs/heads/($cur)" | str trim)
    let parent = (git log $sha --first-parent --simplify-by-decoration --format='%D' --
      | lines
      | str trim
      | where {|l| $l != ''}
      | each {|l| $l | split row ', ' | str trim}
      | flatten
      | each {|r| $r | str replace 'HEAD -> ' '' | str replace 'origin/' ''}
      | where {|r| $r != $cur and not ($r | str starts-with 'tag:') and $r != 'HEAD' and $r in $all}
      | uniq
      | where {|r| $r not-in $seen}
    )

    if ($parent | is-empty) { break }
    let p = ($parent | first)
    $chain = ($chain | append $p)
    $current = $p
  }

  let ch = $chain
  0..(($ch | length) - 1) | each {|i|
    let name = ($ch | get $i)
    let label = if $i == 0 { $name } else { $"('' | fill -c ' ' -w (($i - 1) * 2))← ($name)" }
    if $i < (($ch | length) - 1) {
      let parent = ($ch | get ($i + 1))
      let ahead = (git rev-list --count $"refs/heads/($parent)..refs/heads/($name)" | str trim | into int)
      let behind = (git rev-list --count $"refs/heads/($name)..refs/heads/($parent)" | str trim | into int)
      {branch: $label, ahead: $ahead, behind: $behind}
    } else {
      {branch: $label, ahead: null, behind: null}
    }
  }
}
