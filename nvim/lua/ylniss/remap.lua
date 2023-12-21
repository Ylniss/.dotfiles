-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Navigation
vim.keymap.set({'n', 'v'}, 'Z', '^' , { desc = 'Move to the first character in line' })
vim.keymap.set({'n', 'v'}, 'X', '$' , { desc = 'Move to the end of line' })
vim.keymap.set({'n', 'v'}, '<C-B>', '%' , { desc = 'Jump to matching bracket' })
vim.keymap.set({'n', 'v'}, '<C-J>', '}' , { desc = 'Move down by 1 paragraph' })
vim.keymap.set({'n', 'v'}, '<C-K>', '{' , { desc = 'Move up by 1 paragraph' })
vim.keymap.set({'n', 'v'}, '<C-L>', 'w' , { desc = 'Move right by 1 word' })
vim.keymap.set({'n', 'v'}, '<C-H>', 'b' , { desc = 'Move left by 1 word' })
vim.keymap.set({'n', 'v'}, '<C-G>', '<C-]>' , { desc = 'Go into definition' })
vim.keymap.set({'n', 'v'}, '<CR>', 'o<ESC>' , { desc = 'Add new line in normal mode' })
vim.keymap.set({'n', 'v'}, '<leader>n', '<C-6>' , { desc = 'Go back to previous file' })

-- Commands
vim.keymap.set('n', '<C-s>', vim.cmd.write , { desc = 'Save file' })

-- Move selected code
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Remove space functions because it is a leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

