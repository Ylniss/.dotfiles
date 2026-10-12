# Pick a path with fzf and cd into it.
def --env fcd [] {
  let path = fzf
  if ($path | path type) in ['dir' 'symlink'] {
    cd $path
  } else {
    cd ($path | path dirname)
  }
}

def fvi [] {
  nvim (fzf --preview 'bat --color=always --style=numbers {}')
}
