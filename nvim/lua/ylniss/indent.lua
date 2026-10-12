for width, filetypes in pairs({
	[2] = { "lua", "javascript", "typescript", "html", "json", "nu", "nix" },
	[4] = { "python", "cs", "ps1", "go" },
}) do
	vim.api.nvim_create_autocmd("FileType", {
		pattern = filetypes,
		callback = function()
			vim.bo.tabstop = width
			vim.bo.shiftwidth = width
			vim.bo.expandtab = true
		end,
	})
end
