-- ================================== Basic navigation ================================== 
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

vim.keymap.set({'n', 'v'}, '<C-d>', '<C-d>zz' , { desc = 'scroll half screen down' })
vim.keymap.set({'n', 'v'}, '<C-u>', '<C-u>zz' , { desc = 'scroll half screen up' })


-- ============================= Go to next/previous buffer ============================= 
vim.keymap.set('n', '<leader><Tab>', vim.cmd.bnext, { desc = 'go to next buffer' })
vim.keymap.set('n', '<leader><S-Tab>', vim.cmd.bprevious, { desc = 'go to previous buffer' })


-- ================================= Move selected code ================================= 
vim.keymap.set("v", "<A-j>", "<cmd>m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", "<cmd>m '<-2<CR>gv=gv")


-- ================= Remove space functions because it is a leader key ================== 
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })


-- =============================== Dealing with word wrap =============================== 
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })


-- ================================= Window management ================================= 
vim.keymap.set('n', '<C-Left>', '<C-w><' , { desc = 'decrese window width' })
vim.keymap.set('n', '<C-Right>', '<C-w>>' , { desc = 'increase window width' })
vim.keymap.set('n', '<C-Down>', '<C-w>-' , { desc = 'decrese window height' })
vim.keymap.set('n', '<C-Up>', '<C-w>+' , { desc = 'increase window height' })

vim.keymap.set('n', '<A-Left>', '<C-w>H' , { desc = 'move window left' })
vim.keymap.set('n', '<A-Right>', '<C-w>L' , { desc = 'move window right' })
vim.keymap.set('n', '<A-Down>', '<C-w>J' , { desc = 'move window down' })
vim.keymap.set('n', '<A-Up>', '<C-w>K' , { desc = 'move window up' })

vim.keymap.set('n', '<C-h>', '<C-w>h' , { desc = 'move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j' , { desc = 'move to upper window' })
vim.keymap.set('n', '<C-k>', '<C-w>k' , { desc = 'move to bottom window' })
vim.keymap.set('n', '<C-l>', '<C-w>l' , { desc = 'move to right window' })

vim.keymap.set('n', '<leader>v', vim.cmd.vsplit , { desc = 'open new vertical split window' })
vim.keymap.set('n', '<leader>h', vim.cmd.split , { desc = 'open new horizontal split window' })

local function saveAndClose()
    -- Try to write and quit
    local status, _ = pcall(vim.cmd.wq)
    if not status then
        -- If wq fails, just quit
        vim.cmd('q')
    end
end

vim.keymap.set('n', '<leader>q', saveAndClose, { desc = 'save and close window' })


-- ===================================== Commands ===================================== 
local function smart_save()
    local current_file = vim.fn.expand('%:p')
    if current_file == '' or current_file == nil then
        -- File has no name, open command line with saveas and current directory
        local current_dir = vim.fn.expand('%:p:h') .. '/'
        local saveas_cmd = ':saveas ' .. current_dir
        vim.api.nvim_feedkeys(saveas_cmd, 'n', true)
    else
        -- File already has a name, just write
        vim.cmd.write()
    end
end
vim.keymap.set('n', '<C-s>', smart_save, { desc = 'save file' })
vim.keymap.set('n', '<C-S-s>', vim.cmd.wa, { noremap = true, desc = 'save all changes' })

vim.keymap.set('n', 'wqa', vim.cmd.wqa, { noremap = true, desc = 'save all changes and quit vim' })
vim.keymap.set('n', 'wqA', '<cmd>qa!<CR>', { noremap = true, desc = 'quit vim without saving changes' })

vim.keymap.set('v', '<leader>r' ,'\"hy:%s/<C-r>h//gc<left><left><left>', { desc = 'find and replace' })

vim.keymap.set('n', '<leader>m', '<cmd>Noice<CR>', { noremap = true, desc = 'open messages' })

-- ===================================== Terminal ===================================== 
vim.keymap.set('t', '<esc>', '<C-\\><C-n>', { noremap = true, desc = 'exit terminal mode' })


-- ======================================= LSP ======================================== 
vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover , { desc = 'hover documentation' })


-- ===================================== NeoTree ====================================== 
local function open_neotree_git_root_or_file_dir()
  -- Get the full path of the current file
  local file_path = vim.fn.expand('%:p:h')

  -- Change to the directory of the current file
  vim.cmd('lcd ' .. file_path)

  -- Try to find the Git root directory relative to the current file
  local git_root = vim.fn.system("git rev-parse --show-toplevel")

  -- Check if the git command was successful
  if vim.v.shell_error == 0 and git_root and #git_root > 0 then
    vim.cmd('lcd ' .. git_root)
    -- Open Neotree at the Git root
    vim.cmd("Neotree toggle dir=" .. git_root)
  else
    -- Open Neotree at the current file's directory
    vim.cmd("Neotree toggle reveal_force_cwd")
  end
end

vim.keymap.set('n', '<leader>e', open_neotree_git_root_or_file_dir, { noremap = true, desc = 'open/close explorer' })


-- ============================ Git actions in Fugitive ============================= 
vim.keymap.set('n', '<leader>gs', function()
  vim.cmd.Git()
  vim.cmd.wincmd('L')
end, { desc = 'git status' })
vim.keymap.set('n', '<leader>g>', '<cmd>Git push<CR>' , { noremap = true, desc = 'git push' })
vim.keymap.set('n', '<leader>g<', '<cmd>Git pull<CR>' , { noremap = true, desc = 'git pull' })


-- ================================== Comment.nvim ================================== 
vim.keymap.set('n', '<C-_>', 'gcc' , { remap = true, desc = 'make inline comment' })
vim.keymap.set('v', '<C-_>', 'gc' , { remap = true, desc = 'make inline comment' })
vim.keymap.set('n', '<C-A-_>', 'gbc' , { remap = true, desc = 'make block comment' })
vim.keymap.set('v', '<C-A-_>', 'gb' , { remap = true, desc = 'make block comment' })


-- ========================== Document existing key chains ========================== 
local whichKey = require('which-key')
whichKey.register {
  ['<leader>c'] = { name = 'code', _ = 'which_key_ignore' },
  ['<leader>e'] = { name = 'explore', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = 'git', _ = 'which_key_ignore' },
  ['<leader>gh'] = { name = 'git hunks', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = 'search', _ = 'which_key_ignore' },
}

-- Required for visual <leader>hs (hunk stage) to work
whichKey.register({
  ['<leader>'] = { name = 'VISUAL <leader>' },
  ['<leader>h'] = { 'git hunk' },
}, { mode = 'v' })
