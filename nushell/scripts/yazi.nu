# cd into yazi's exit path. On termux this is overridden by an extern in
# `/usr/share/nushell/vendor/autoload/yazi.nu`; see `android-vendor-autoload/yazi.nu`.
def --env yazi [...args] {
  let cwd_file = (mktemp)
  ^yazi ...$args --cwd-file $cwd_file
  let target_dir = (open --raw $cwd_file | str trim)
  rm -f $cwd_file
  if ($target_dir != "" and $target_dir != $env.PWD) { cd $target_dir }
}

alias e = yazi

