# Change dir with fzf
def --env fcd [] {
  let path = fzf
  let type = $path | path type
  if ($path | path exists) {
    if $type in ['dir' 'symlink'] {
      cd $path
    } else {
      cd ($path | path dirname)
    }
  }
}

# Open file in nvim with fzf, previewing the hovered file with bat
def fvi [] {
  nvim (fzf --preview 'bat --color=always --style=numbers {}')
}
