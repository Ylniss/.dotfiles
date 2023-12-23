require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'c_sharp',
    'javascript', 'typescript',
    'html', 'scss',
    'vimdoc', 'vim',
    'lua', 'bash',
    'gitignore',
  },

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
