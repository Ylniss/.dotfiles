-- Basic navigation
vim.keymap.set({'n', 'v'}, 'Z', '^' , { desc = 'move to the first character in line' })
vim.keymap.set({'n', 'v'}, 'X', '$' , { desc = 'move to the end of line' })
vim.keymap.set({'n', 'v'}, '<C-b>', '%' , { desc = 'jump to matching bracket' })
vim.keymap.set({'n', 'v'}, '<C-g>', '<C-]>' , { desc = 'go into definition' })
vim.keymap.set({'n', 'v'}, '<CR>', 'o<ESC>' , { desc = 'add new line in normal mode' })
vim.keymap.set({'n', 'v'}, '<leader>n', '<C-6>' , { desc = 'go back to previous file' })

vim.keymap.set({'n', 'v'}, 'J', '}' , { desc = 'move down by 1 paragraph' })
vim.keymap.set({'n', 'v'}, 'K', '{' , { noremap = true, desc = 'move up by 1 paragraph' })
vim.keymap.set({'n', 'v'}, 'L', 'w' , { desc = 'move right by 1 word' })
vim.keymap.set({'n', 'v'}, 'H', 'b' , { desc = 'move left by 1 word' })

-- Move selected code
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Window management
vim.keymap.set('n', '<C-Left>', '<C-w><' , { desc = 'decrese window width' })
vim.keymap.set('n', '<C-Right>', '<C-w>>' , { desc = 'increase window width' })
vim.keymap.set('n', '<C-Down>', '<C-w>-' , { desc = 'decrese window height' })
vim.keymap.set('n', '<C-Up>', '<C-w>+' , { desc = 'increase window height' })

vim.keymap.set('n', '<C-h>', '<C-w>h' , { desc = 'move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j' , { desc = 'move to upper window' })
vim.keymap.set('n', '<C-k>', '<C-w>k' , { desc = 'move to bottom window' })
vim.keymap.set('n', '<C-l>', '<C-w>l' , { desc = 'move to right window' })

-- Commands
vim.keymap.set('n', '<C-s>', vim.cmd.write, { desc = 'save file' })
vim.keymap.set('n', '<C-S-s>', vim.cmd.wa, { noremap = true, desc = 'save all changed files' })

-- LSP
vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover , { desc = 'hover documentation' })

-- Remove space functions because it is a leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- NeoTree
vim.keymap.set('n', '<leader>e', ':Neotree<CR>' , { desc = 'open explorer' })

-- Git actions in Fugitive
vim.keymap.set('n', '<leader>gs', function()
  vim.cmd.Git()
  vim.cmd.wincmd('L')
end, { desc = 'git status' })
vim.keymap.set('n', '<leader>g>', ':Git push<CR>' , { noremap = true, desc = 'git push' })
vim.keymap.set('n', '<leader>g<', ':Git pull<CR>' , { noremap = true, desc = 'git pull' })

-- Comment.nvim
vim.keymap.set('n', '<C-_>', 'gcc' , { remap = true, desc = 'make inline comment' })
vim.keymap.set('v', '<C-_>', 'gc' , { remap = true, desc = 'make inline comment' })
vim.keymap.set('n', '<C-A-_>', 'gbc' , { remap = true, desc = 'make block comment' })
vim.keymap.set('v', '<C-A-_>', 'gb' , { remap = true, desc = 'make block comment' })

-- Document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = 'code', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = 'document', _ = 'which_key_ignore' },
  ['<leader>e'] = { name = 'explore', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = 'git', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = 'git hunk', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = 'rename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = 'search', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = 'workspace', _ = 'which_key_ignore' },
}

-- Required for visual <leader>hs (hunk stage) to work
require('which-key').register({
  ['<leader>'] = { name = 'VISUAL <leader>' },
  ['<leader>h'] = { 'git hunk' },
}, { mode = 'v' })
