-- ========================================================
-- md-render.nvim
-- Markdown rendering in a separate float, split or tab view
-- ========================================================
return {
	"delphinus/md-render.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "MdRender" },
	keys = {
		{ "<leader>mp", "<Plug>(md-render-preview)", ft = "markdown", desc = "markdown: preview in float (toggle)" },
		-- <Plug>(md-render-split) ignores split modifiers, so it always opens horizontally.
		{ "<leader>ms", "<cmd>vertical MdRender split<CR>", ft = "markdown", desc = "markdown: preview in vertical split" },
		{ "<leader>mt", "<Plug>(md-render-preview-tab)", ft = "markdown", desc = "markdown: preview in tab (toggle)" },
	},
}
