alias vi = nvim
alias vim = nvim

# Remove stale nvim temp files: shada tmp + swap files orphaned by dead nvim processes.
def nvim-clean-temp [] {
  let data_dir = if (is-windows) {
    $"($env.LOCALAPPDATA)/nvim-data"
  } else {
    $"($nu.home-dir)/.local/share/nvim"
  }
  let shada_dir = $"($data_dir)/shada"
  rm --force ($shada_dir | path join "main.shada.tmp.*" | into glob)

  let swap_dir = $"($data_dir)/swap"
  let live_pids = (ps | where name =~ "nvim" | get pid)
  # The swap file header (ZeroBlock in nvim source) stores the owner PID at offset 24.
  # The fields before the PID take 24 bytes: b0_id, b0_version, b0_page_size, b0_mtime, b0_ino.
  let removed = glob ($swap_dir | path join "*.sw?" | str replace --all '\' '/') | each { |f|
    try {
      let pid = (open --raw $f | bytes at 24..<28 | into int --endian little)
      if $pid not-in $live_pids { rm $f; $f }
    }
  }
  let count = ($removed | length)
  if $count > 0 { print $"nvim-clean-temp: removed ($count) orphaned swap file\(s\)" }
}

