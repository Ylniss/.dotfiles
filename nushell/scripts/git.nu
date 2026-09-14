alias gi = lazygit
alias gits = git status

# Stage changes in a path.
# If you give no path, or the path does not exist, stage the current directory.
def gita --wrapped [path?: string, ...opts] {
  let target = if (($path | is-not-empty) and ($path | path exists)) { $path } else { "." }
  git add ...$opts $target
}

# Show git log — compact table by default, --graph (-g) for the commit graph.
def gitl [--graph (-g)] {
  if $graph {
    git log --all --decorate --oneline --graph --pretty=format:'%C(auto)%h %<(12,trunc)%an %<(16,trunc)%ar %s %d'
  } else { 
    git log --reverse $"--pretty=(ansi yellow)%h(ansi reset)»¦«%s»¦«%aN»¦«%as" | lines | split column "»¦«" commit message name date | update message { str substring 0..65 } | sort-by date
  }  
}

# Show unstaged then staged changes under labeled headers.
def gitd --wrapped [...opts] {
  if (git diff | is-not-empty) {
    print $"(ansi red)\n --------------------- Unstaged Changes --------------------- (ansi reset)"
    git diff ...$opts
  }
  if (git diff --staged | is-not-empty) {
    print $"(ansi green)\n --------------------- Staged Changes --------------------- (ansi reset)"
    git diff --staged ...$opts
  }
}

def gitc --wrapped [...opts, message?: string] {
  if ($message | is-not-empty) {
    git commit ...$opts -m $message 
  } else {
    git commit ...$opts
  }
}

# Git Push: Pushes to origin, optionally targeting a specific branch.
def gitp --wrapped [branch?: string, ...opts] {
  if ($branch | is-not-empty) {
    git push origin $branch ...$opts
  } else {
    git push ...$opts
  }
}

alias gitch = git checkout
alias gitb = git branch
alias gitbch = git checkout -b

def gitmrg [branch: string] {
  let current_branch = git rev-parse --abbrev-ref HEAD
  git fetch --all

  # Set the upstream to origin/<current branch> if the current branch has none.
  if (git rev-parse --abbrev-ref --symbolic-full-name @{u} | is-empty) {
    git branch $'--set-upstream-to=origin/($current_branch)' $current_branch
  }

  git merge $"origin/($branch)" --allow-unrelated-histories
}

# Initialize new git repo
def giti [
  repo_name?: string # New repo name, if not specified it will be created in current working dir
  --github (-g) # Create repo also on github
] {
  let dir = ($repo_name | default ".")
  git init $dir

  if $github {
    let source = ($dir | path expand)
    gh auth login
    gh repo create ($source | path basename) --private $"--source=($source)"
  }
  touch ($dir | path join '.gitignore')
}

# Git Worktree Add: create a branch in a new worktree at ../<current dir>-<branch>.
# Then cd into the worktree and open layout-dev in WezTerm. Use --stay to skip both.
def --env gitwta [branch: string, --stay (-s)] {
  let dir_name = (pwd | path basename)
  let path = $"../($dir_name)-($branch)"
  git worktree add $path -b $branch
  if $stay { return }
  cd $path
  if 'WEZTERM_PANE' in $env {
    layout-dev
  }
}

# Git Worktree Finish: push the worktree branch and merge it into the base branch.
# Then delete the worktree and its local branch. Pass . for the current worktree.
def --env gitwtf [path: string] {
  let worktree_path = if $path == "." { pwd } else { $path | path expand }

  let branch = try { git -C $worktree_path rev-parse --abbrev-ref HEAD } catch {
    print $"(ansi red)Not a git repository(ansi reset)"
    return
  }

  # Git lists the main worktree (base repo) first.
  let base_path = (git -C $worktree_path worktree list --porcelain
    | lines
    | first
    | str replace 'worktree ' '')

  let git_dir = (git -C $worktree_path rev-parse --path-format=absolute --git-dir)
  let common_dir = (git -C $worktree_path rev-parse --path-format=absolute --git-common-dir)
  if $git_dir == $common_dir {
    print $"(ansi red)This is the main worktree — refusing to remove(ansi reset)"
    return
  }

  if not ($base_path | path exists) {
    print $"(ansi red)Base repo not found at ($base_path)(ansi reset)"
    return
  }

  let dirty = (git -C $worktree_path status --porcelain)
  if ($dirty | is-not-empty) {
    print $"(ansi red)Uncommitted changes — commit first(ansi reset)"
    return
  }

  # Push worktree branch, merge into base branch, push
  let base_branch = (git -C $base_path rev-parse --abbrev-ref HEAD)
  try {
    git -C $worktree_path push origin $branch
    git -C $worktree_path fetch origin
    git -C $worktree_path merge $"origin/($base_branch)"
    git -C $worktree_path push origin $"HEAD:($base_branch)"
  } catch {
    print $"(ansi red)Push/merge failed — resolve and retry(ansi reset)"
    return
  }

  # cd out before removal (only for `.`)
  if $path == "." {
    cd $base_path
  }

  try { git -C $base_path pull }

  # Remove directory (retry once for Windows handle release)
  try { rm -rf $worktree_path } catch {
    sleep 1sec
    try { rm -rf $worktree_path } catch {
      print $"(ansi yellow)Warning: could not remove directory — remove it manually(ansi reset)"
    }
  }

  git -C $base_path worktree prune
  try { git -C $base_path branch -D $branch }
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
  let local_branches = (git branch --format='%(refname:short)' | lines)
  mut current = (git rev-parse --abbrev-ref HEAD)
  mut chain = [$current]

  loop {
    if $current in ['main' 'master'] { break }
    let cur = $current
    let seen = $chain

    let candidates = (git log $"refs/heads/($cur)" --first-parent --simplify-by-decoration --format='%D' --
      | lines
      | split row ', '
      | str replace 'HEAD -> ' ''
      | str replace 'origin/' ''
      | where {|r| $r in $local_branches and $r not-in $seen}
    )

    if ($candidates | is-empty) { break }
    let parent = ($candidates | first)
    $chain = ($chain | append $parent)
    $current = $parent
  }

  let ch = $chain
  0..(($ch | length) - 1) | each {|i|
    let name = ($ch | get $i)
    let label = if $i == 0 { $name } else { $"('' | fill -c ' ' -w (($i - 1) * 2))← ($name)" }
    if $i == (($ch | length) - 1) { return {branch: $label, ahead: null, behind: null} }
    let parent = ($ch | get ($i + 1))
    let ahead = (git rev-list --count $"refs/heads/($parent)..refs/heads/($name)" | str trim | into int)
    let behind = (git rev-list --count $"refs/heads/($name)..refs/heads/($parent)" | str trim | into int)
    {branch: $label, ahead: $ahead, behind: $behind}
  }
}
