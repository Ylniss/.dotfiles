-- Basic navigation
vim.keymap.set({'n', 'v'}, 'Z', '^' , { desc = 'Move to the first character in line' })
vim.keymap.set({'n', 'v'}, 'X', '$' , { desc = 'Move to the end of line' })
vim.keymap.set({'n', 'v'}, '<C-b>', '%' , { desc = 'Jump to matching bracket' })
vim.keymap.set({'n', 'v'}, '<C-g>', '<C-]>' , { desc = 'Go into definition' })
vim.keymap.set({'n', 'v'}, '<CR>', 'o<ESC>' , { desc = 'Add new line in normal mode' })
vim.keymap.set({'n', 'v'}, '<leader>n', '<C-6>' , { desc = 'Go back to previous file' })

vim.keymap.set({'n', 'v'}, 'J', '}' , { desc = 'Move down by 1 paragraph' })
vim.keymap.set({'n', 'v'}, 'K', '{' , { noremap = true, desc = 'Move up by 1 paragraph' })
vim.keymap.set({'n', 'v'}, 'L', 'w' , { desc = 'Move right by 1 word' })
vim.keymap.set({'n', 'v'}, 'H', 'b' , { desc = 'Move left by 1 word' })

-- Window management
vim.keymap.set('n', '<C-Left>', '<C-w><' , { desc = 'Decrese window width' })
vim.keymap.set('n', '<C-Right>', '<C-w>>' , { desc = 'Increase window width' })
vim.keymap.set('n', '<C-Down>', '<C-w>-' , { desc = 'Decrese window height' })
vim.keymap.set('n', '<C-Up>', '<C-w>+' , { desc = 'Increase window height' })

vim.keymap.set('n', '<C-h>', '<C-w>h' , { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j' , { desc = 'Move to upper window' })
vim.keymap.set('n', '<C-k>', '<C-w>k' , { desc = 'Move to bottom window' })
vim.keymap.set('n', '<C-l>', '<C-w>l' , { desc = 'Move to right window' })

-- Commands
vim.keymap.set('n', '<C-s>', vim.cmd.write , { desc = 'Save file' })

-- LSP
vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover , { desc = 'Hover Documentation' })

-- Move selected code
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Remove space functions because it is a leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- NeoTree
vim.keymap.set('n', '<leader>e', ':Neotree<CR>' , { desc = 'Open Explorer' })
