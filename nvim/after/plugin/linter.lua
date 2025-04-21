require("lint").linters_by_ft = {
	go = { "golangcilint" },
	tf = { "tflint" },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		require("lint").try_lint()
	end,
})
