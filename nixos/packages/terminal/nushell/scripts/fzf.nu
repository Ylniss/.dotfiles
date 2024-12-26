# Change dir with fzf
def fcd --env [] {
  let path = fzf
  let type = $path | path type
  if ($path | path exists) {
    if $type =~ 'dir' {
      cd $path
    } else {
      cd ($path | path dirname)
    }
  }
}

