local actions = require('telescope.actions')

require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
      n = {
        ["l"] = actions.select_default + actions.center,
        ["h"] = actions.select_horizontal,
        ["v"] = actions.select_vertical,
      },
    },
  },
}

-- Find the git root directory based on the current buffer's path
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

local telescope = require('telescope.builtin')

local function telescope_live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    telescope.live_grep {
      search_dirs = { git_root },
    }
  end
end

local function telescope_live_grep_open_files()
  telescope.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end

local function telescope_fuzzy_find_small_window()
  telescope.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end

vim.keymap.set('n', '<leader><space>', telescope.buffers, { desc = 'find existing buffers' })
vim.keymap.set('n', '<leader>?', telescope.oldfiles, { desc = 'find recently opened files' })
vim.keymap.set('n', '<leader>/', telescope_fuzzy_find_small_window, { desc = 'fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files, { desc = 'search in Open Files' })
vim.keymap.set('n', '<leader>st', telescope.builtin, { desc = 'search select Telescope' })
vim.keymap.set('n', '<leader>ss', telescope.git_files, { desc = 'search git files' })
vim.keymap.set('n', '<leader>sf', telescope.find_files, { desc = 'search files' })
vim.keymap.set('n', '<leader>sp', "<cmd>Telescope find_files cwd=~/stuff/repo/<CR>", { desc = 'search repo' })
vim.keymap.set('n', '<leader>sh', telescope.help_tags, { desc = 'search help' })
vim.keymap.set('n', '<leader>sw', telescope.grep_string, { desc = 'search current word' })
vim.keymap.set('n', '<leader>sg', telescope_live_grep_git_root, { desc = 'search by grep on git root' })
vim.keymap.set('n', '<leader>sd', telescope.diagnostics, { desc = 'search diagnostics' })
vim.keymap.set('n', '<leader>sb', telescope.marks, { desc = 'search bookmarks' })
vim.keymap.set('n', '<leader>sr', telescope.resume, { desc = 'search resume' })
