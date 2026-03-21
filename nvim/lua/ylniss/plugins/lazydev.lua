-- ========================================================
-- Lazydev
-- Neovim Lua API type definitions for lua_ls
-- ========================================================
return {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		},
	},
}
