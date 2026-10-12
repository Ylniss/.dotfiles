# On termux a vendor extern overrides this def; android-vendor-autoload/yazi.nu re-sources it.
def --env yazi [...args] {
  let cwd_file = (mktemp)
  ^yazi ...$args --cwd-file $cwd_file
  let target_dir = (open --raw $cwd_file | str trim)
  rm -f $cwd_file
  if ($target_dir != "" and $target_dir != $env.PWD) { cd $target_dir }
}

alias e = yazi

