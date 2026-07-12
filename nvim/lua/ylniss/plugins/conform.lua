-- ========================================================
-- Conform
-- Format-on-save with per-filetype formatters
-- ========================================================
return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { timeout_ms = 500, lsp_format = "fallback" }
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			nix = { "alejandra" },
			json = { "prettier" },
			yaml = { "prettier" },
		},
	},
}
