# Termux ships `export extern yazi` in /usr/share/nushell/vendor/autoload/yazi.nu
# which loads after config.nu and shadows the def in scripts/general.nu.
# Symlinked to ~/.local/share/nushell/vendor/autoload/ (later autoload dir) to win.
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
