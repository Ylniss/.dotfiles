alias repo = cd $env.repo
alias games = cd $env.games
alias dwn = cd $env.downloads

# Make directory and enter inside
def mkdircd --env [dirName: string] {
  mkdir $dirName
  cd $dirName
}

# -------------- FZF -------------- 

# Change dir with fzf
def fcd --env [] {
  let path = fzf
  let type = file $path
  if ($path | path exists) {
    if $type =~ 'directory' or $type =~ 'symlink' {
      cd $path
    } else {
      cd ($path | path dirname)
    }
  }
}

# Open file in nvim with fzf
def fvi [] {
  nvim (fzf) 
}

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
