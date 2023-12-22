-- On vim start open NERDTree and put cursor in other window
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    command = "NERDTree | wincmd p"
})


local function quit_vim_if_only_nerdtree_is_left()
    local tab_count = #vim.api.nvim_list_tabpages()
    local win_count = #vim.api.nvim_tabpage_list_wins(0)

    -- Check if NERDTree is the only window in the only tab
    if tab_count == 1 and win_count == 1 then
        -- Get the current buffer number
        local buf = vim.api.nvim_get_current_buf()

        -- Safely check if the 'b:NERDTree' variable exists
        local is_nerdtree = pcall(function()
            return vim.api.nvim_buf_get_var(buf, "NERDTree")
        end)

        -- Check if NERDTree is a tab tree
        local is_tab_tree = false
        if is_nerdtree then
            is_tab_tree = vim.api.nvim_buf_get_var(buf, "NERDTree").isTabTree
        end

        -- Debug print
        print("is_nerdtree: " .. tostring(is_nerdtree) .. "; is_tab_tree: " .. tostring(is_tab_tree))

        -- Exit if it's NERDTree and it's a tab tree
        if is_nerdtree and is_tab_tree then
            vim.api.nvim_command('quit')
        end
    end
end

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = quit_vim_if_only_nerdtree_is_left
})
