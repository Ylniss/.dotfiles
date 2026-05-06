const TINTY_FAVS = [
  base16-da-one-sea
  base16-gruvbox-material-dark-hard
  base16-hardhacker
  base16-rose-pine
  base16-tokyo-night-terminal-dark
  base16-everforest-dark-hard
  base16-black-metal-bathory
  base16-irblack
]

# Pick any tinty scheme via fzf and apply it.
def tinty-apply [] {
  let pick = (tinty list | fzf | str trim)
  if ($pick | is-not-empty) {
    tinty apply $pick
  }
}

# Pick a scheme via fzf from a favorites list and apply it.
def tinty-fav-apply [] {
  let pick = ($TINTY_FAVS | str join "\n" | fzf | str trim)
  if ($pick | is-not-empty) {
    tinty apply $pick
  }
}
