const TINTY_FAVS = [
  base16-da-one-sea
  base16-gruvbox-material-dark-hard
  base16-hardhacker
  base16-rose-pine
  base16-tokyo-night-terminal-dark
  base16-everforest-dark-hard
  base16-black-metal-bathory
  base16-irblack
  base16-pastelon-de-amarillos-dark
  base16-cacao
  base16-moonlight
  base16-stella
  base16-neovim-dark
  base16-kanagawa
]

# Pick a scheme from the piped-in list via fzf and apply it.
def tinty-pick-and-apply []: string -> nothing {
  let pick = ($in | fzf | str trim)
  if ($pick | is-not-empty) {
    tinty apply $pick
  }
}

# Pick any tinty scheme via fzf and apply it.
def tinty-apply [] {
  tinty list | tinty-pick-and-apply
}

# Pick a scheme via fzf from a favorites list and apply it.
def tinty-fav-apply [] {
  $TINTY_FAVS | str join "\n" | tinty-pick-and-apply
}
