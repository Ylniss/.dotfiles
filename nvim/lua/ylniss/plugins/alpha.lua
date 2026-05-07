-- ========================================================
-- Alpha
-- Greeting dashboard screen on startup
-- ========================================================
return {
	"goolord/alpha-nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local dashboard = require("alpha.themes.dashboard")
		local logo = [[
@@@  @@@  @@@@@@@@   @@@@@@   @@@  @@@  @@@  @@@@@@@@@@   
@@@@ @@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@@@@  
@@!@!@@@  @@!       @@!  @@@  @@!  @@@  @@!  @@! @@! @@!  
!@!!@!@!  !@!       !@!  @!@  !@!  @!@  !@!  !@! !@! !@!  
@!@ !!@!  @!!!:!    @!@  !@!  @!@  !@!  !!@  @!! !!@ @!@  
!@!  !!!  !!!!!:    !@!  !!!  !@!  !!!  !!!  !@!   ! !@!  
!!:  !!!  !!:       !!:  !!!  :!:  !!:  !!:  !!:     !!:  
:!:  !:!  :!:       :!:  !:!   ::!!:!   :!:  :!:     :!:  
 ::   ::   :: ::::  ::::: ::    ::::     ::  :::     ::   
::    :   : :: ::    : :  :      :      :     :      :    
]]

		dashboard.section.header.val = vim.split(logo, "\n")

		dashboard.section.buttons.val = {
			dashboard.button("space s f", "󰈞  Search file"),
			dashboard.button("space s g", "󰊄  Search text with grep"),
			dashboard.button("space s k", "󰌌  Search keymaps"),
			dashboard.button("space ?", "󰋚  Recently used files"),
			dashboard.button("space e", "󰙅  Explorer"),
			dashboard.button(
				"c",
				"󰒓  Nvim config",
				"<cmd>lcd ~/stuff/repo/.dotfiles | e ~/stuff/repo/.dotfiles/nvim/lua/ylniss/init.lua<CR>"
			),
			dashboard.button("l", "󰚥  Lazy config", "<cmd>Lazy<CR>"),
			dashboard.button("m", "󱌣  Mason config", "<cmd>Mason<CR>"),
			dashboard.button("q", "󰐥  Quit Neovim", "<cmd>qa<CR>"),
		}

		dashboard.section.footer.val = " 󰈈 󰈈 󰈈  B  R  U  H 󰈈 󰈈 󰈈 "

		dashboard.section.header.opts.hl = "Function"
		dashboard.section.buttons.opts.hl = "Keyword"
		dashboard.section.footer.opts.hl = "Type"

		dashboard.opts.opts.noautocmd = true

		require("alpha").setup(dashboard.opts)
	end,
}
