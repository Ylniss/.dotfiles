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
@::::::=%%**:: ##*#@@@@@@@@@@@@@@@@@##@@@@@@@##@%+%@@@@@@@@@@@@@@@%**#= :.#*@#:::::%
%        %@==@= @@@@@@@#+@@@@@@#::=+=:.=@@@*=====-::%@@@#::-*-=@@@@@@# #@ %@=      #
%         @%@@@@#@@%=-+=--=#@@@@+ : = :@@@@@= + :: #@@@@@* :: -+=%@@@#@@@@#:       #
%          #@@@@@@@@= - =. #@@@#:@+ #@+=@@@#*@@ =@#:@@@@==@-.#. @@@@@@@@@%         #
%           +@@@@@@#.%% +@@#%@@@@@@.@@@@@@@@@@@:#@@@@@@@@@@-=@@#*@@@@@@@=          #
%            +@@@@@@@@@++@@@@@@@@@@@@@@-#*@.*@@@@@@:%+#*@@@%@@@@@@@@@@@:           #
%             =@@@@@@@@@@@@:-@* +@@#%@@%:  +@@@=%@@+   =@@@%@% *%#%@@%             #
%              :@@*#@::@*#@@#++@@@#===@@@@@@@#:#-*@@@@@@@*=+%@+ :.:@+              #
%               .%=::=@#-= %@@@@@@+=#+#%@@@@#*+#+*#@@@@@#=*-:@@@@@@:               #
%                .@@@@@*#@+#=@@@@....:=:#@@#-=#=#=-#@@#.: =::-@@@%.                #
%                 .%@@:.::+===%@==:.@-.===+:-: # :--+=+= =@:-=+@#                  #
%                   @+==.+=:=+-#=+===                     ..::=#    +:             #
%                   =-==-: #.- % = *   :*#%%%%#*=:=:  .=--*##*#=    *#             #
%                   # + = --:-:= =.= -=   :=**+.  =.  :#: =+=-@:     @+            #
%                  --.=.- % = * -:=:   *#::+##*#@*    =@+.=**+@%:     *:           #
%                  + # -:=:.=.= * =  -%@@*@#@%@+@:    :@#@@@@@@:       :           #
%                 -::= =.+ =.=.=::-       :++*@@:     .%+=+==-@#        :          #
%                .= # -:=. =:- # =          .:         *:=*   % *       %          #
%                =.=. +.- # -.+ :-              :.     ==    .%*:=     =%          #
%               +::- # =.=.:-:: *.+            += .=*: +=    -=*=#++=+::           #
%              *: = * :--: + = #==%@+     **-   :=-::#-    :+#%#*#:.=@.            #
%       .-.   *  = +  +:- # =:*:*=+@@@+  :#    #@@@+ -@@#%@+#@***=.                #
%     =-   ===  * =:.*.=.+ =-=:#===:+@@@@::%@%*=.:=+##%@@@#@@@=++=                 #
%     # =  -+ -= =.:=:=.= %%= :+-=-=+:=@@@@:   +-===+==== +@@#==+*                 #
%     *  .. -= =- -:=:.++@ #=+=:*:=+:+. :@@@@%=     *+  :#@@#=:=:#@#:              #
%.+@@@@@@@=  += .*:#-+@@@@@::=- :+=:#  =:=-%@@@@@@@@@@*@@@@@=.* ++@@@@@@=          #
@@@@@@@@@@@@@@@@@@@@@@%==#@@@@@@@:=.+:-:=:+-=#%@@@@@@@@@@@-+=-:+.#@@@==#@@@%=.     #
@@@@@@@@@@@@@@@@@@@@@+-::-:#@@@@@*:==::=.#.-+-  =+*#@@#+* #:=**#@@@*=-:=*%@@@@@#=  #
@@@@@@@@@@@@@@@@@@@@@@* + ++@@@@@@@+   =@# *:- +-=:%@@:=:==:--@@@@@-=.*.+@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@%#@@:@@@@@@@@@@@@@@@@ -=  :*:#@@@@::##- %@@@@@@@:@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=:::#@@@@@@@@**%@@@@@@@@@@@@@@@@@@@@@@@@
]]

		dashboard.section.header.val = vim.split(logo, "\n")

		dashboard.section.buttons.val = {
			dashboard.button("space s f", " > Search file"),
			dashboard.button("space s p", " > Search repo"),
			dashboard.button("space s g", "⚡> Search text with grep"),
			dashboard.button("space s b", " > Search bookmarks"),
			dashboard.button("space ?", "� > Recently used files"),
			dashboard.button("space e", " > Explorer"),
			dashboard.button("n", " > New file", "<cmd>ene <BAR> startinsert <CR>"),
			dashboard.button(
				"c",
				" > Nvim config",
				"<cmd>lcd ~/stuff/repo/.dotfiles | e ~/stuff/repo/.dotfiles/nvim/lua/ylniss/init.lua<CR>"
			),
			dashboard.button("l", "󰚥 > Lazy config", "<cmd>Lazy<CR>"),
			dashboard.button("m", "󱌣 > Mason config", "<cmd>Mason<CR>"),
			dashboard.button("q", "⏻ > Quit Neovim", "<cmd>qa<CR>"),
		}

		dashboard.section.footer.val = " 󰈈 󰈈 󰈈  WE SMOKE ACID BITCH! 󰈈 󰈈 󰈈 "

		vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#ffff61", bg = "none" })
		vim.api.nvim_set_hl(0, "DashboardButtons", { fg = "#FFA500", bg = "none" })

		dashboard.section.footer.opts.hl = "Type"
		dashboard.section.header.opts.hl = "DashboardHeader"
		dashboard.section.buttons.opts.hl = "DashboardButtons"

		dashboard.opts.opts.noautocmd = true

		require("alpha").setup(dashboard.opts)
	end,
}
