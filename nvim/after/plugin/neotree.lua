require("neo-tree").setup({
  close_if_last_window = false,
  window = {
    width = 45,
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    group_empty_dirs = false,
  },
  buffers = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    group_empty_dirs = false,
  },
})
