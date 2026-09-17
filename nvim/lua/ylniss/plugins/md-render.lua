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
	config = function()
		-- HACK: md-render has no option to stop truncating code blocks and tables with "…".
		-- Start every expandable block expanded. This depends on the internal build_content
		-- and expand_state, so a plugin update can break it silently.
		local preview = require("md-render.preview")
		local build_content = preview.build_content
		preview.build_content = function(lines, opts)
			setmetatable(opts.expand_state, {
				__index = function()
					return true
				end,
			})
			return build_content(lines, opts)
		end
	end,
}
