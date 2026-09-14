# Pick a path with fzf and change directory to it. For a file, use its parent directory.
def --env fcd [] {
  let path = fzf
  if ($path | path type) in ['dir' 'symlink'] {
    cd $path
  } else {
    cd ($path | path dirname)
  }
}

# Open file in nvim with fzf, previewing the hovered file with bat
def fvi [] {
  nvim (fzf --preview 'bat --color=always --style=numbers {}')
}
