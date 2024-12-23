require("conform").setup({
	format_on_save = function(bufnr)
		-- Disable with a global or buffer-local variable
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 500, lsp_fallback = true }
	end,

	formatters_by_ft = {
		cs = { "csharpier" },
		go = { "gomimports", "gofumpt" },
		lua = { "stylua" },
		nix = { "alejandra" },
		markdown = { { "mdformat", "prettierd", "prettier" } },
		javascript = { { "prettierd", "prettier" } },
		typescript = { "prettier" },
		html = { { "prettierd", "prettier" } },
		css = { { "prettierd", "prettier" } },
		scss = { { "prettierd", "prettier" } },
		json = { { "prettierd", "prettier" } },
		yaml = { { "prettierd", "prettier", "yamlfmt" } },
	},
})
