alias vi = nvim
alias vim = nvim

# Remove stale nvim temp files: shada tmp + swap files orphaned by dead nvim processes.
def nvim-clean-temp [] {
  let shada_dir = if (is-windows) {
    $"($env.LOCALAPPDATA)/nvim-data/shada"
  } else {
    $"($nu.home-dir)/.local/share/nvim/shada"
  }
  glob ($shada_dir | path join "main.shada.tmp.*" | str replace --all '\' '/') | each { rm $in } | ignore

  let swap_dir = if (is-windows) {
    $"($env.LOCALAPPDATA)/nvim-data/swap"
  } else {
    $"($nu.home-dir)/.local/share/nvim/swap"
  }
  let live_pids = (ps | where name =~ "nvim" | get pid)
  # nvim's ZeroBlock header stores owner PID as u32 LE at offset 24 (b0_id + b0_version + b0_page_size + b0_mtime + b0_ino = 24 bytes)
  let removed = glob ($swap_dir | path join "*.sw?" | str replace --all '\' '/') | each { |f|
    try {
      let pid = (open --raw $f | bytes at 24..<28 | into int --endian little)
      if $pid not-in $live_pids { rm $f; $f }
    } catch { }
  } | compact
  let count = ($removed | length)
  if $count > 0 { print $"nvim-clean-temp: removed ($count) orphaned swap file\(s\)" }
}

