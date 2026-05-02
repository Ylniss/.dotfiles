# cd into yazi's exit path. On termux this is overridden by an extern in
# `/usr/share/nushell/vendor/autoload/yazi.nu`; see `android-vendor-autoload/yazi.nu`.
def --env yazi [...args] {
  let tmp = (mktemp)
  ^yazi ...$args --cwd-file $tmp
  try {
    let target_dir = (open --raw $tmp | str trim)
    rm -f $tmp
    try {
      if ($target_dir != "" and $target_dir != $env.PWD) { cd $target_dir }
    } catch { |e| print -e $'yazi: Can not change to ($target_dir): ($e | get debug)' }
  } catch {
    |e| print -e $'yazi: Reading ($tmp) returned an error: ($e | get debug)'
  }
}

alias e = yazi

