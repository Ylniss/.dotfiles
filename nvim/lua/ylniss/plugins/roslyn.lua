-- ========================================================
-- Roslyn
-- C# language server (Microsoft's official Roslyn LSP)
-- ========================================================
return {
	"seblyng/roslyn.nvim",
	ft = "cs",
	opts = {
		filewatching = "off",
		args = {
			"--stdio",
			"--logLevel=Information",
			"--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
		},
	},
	config = function(_, opts)
		require("roslyn").setup(opts)

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.cs",
			callback = function(args)
				if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
					return
				end
				vim.lsp.buf.format({ bufnr = args.buf })
			end,
		})
	end,
}
