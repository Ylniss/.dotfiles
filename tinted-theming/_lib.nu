# Shared helpers for render-* scripts.
# Prefer $env.TINTY_SCHEME_SLUG (set when running as a tinty hook); fall back
# to `tinty current` so the scripts also work when invoked directly (set-opacity.nu).

export def palette [] {
  let slug = ($env.TINTY_SCHEME_SLUG? | default (^tinty current | str trim | str replace -r '^base16-' ''))
  let path = $"($env.HOME)/.local/share/tinted-theming/tinty/repos/schemes/base16/($slug).yaml"
  (open $path).palette
}

export def alpha-hex [opacity: float] {
  ^printf '%02x' ($opacity * 255 | math round | into int)
}
