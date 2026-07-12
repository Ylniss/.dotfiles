# Change dir with fzf
def fcd --env [] {
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

# Open file in nvim with fzf
def fvi [] {
  nvim (fzf)
}
