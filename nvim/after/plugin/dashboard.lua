local dashboard = require("alpha.themes.dashboard")
local logo = [[
      ░░░░░░ ░░░░ ░░░░░░░░░░░░░   ░███████████████                    ░░  ░░  ░░▓█  
       ░░░  ░░░░░░░░░░░░░░░░▒▓▓████             ░████                  ░     ▒░░    
        ░ ░   ░░▒▒░░░░░░░░▒████                  ▒░ ███   ░   ░          ░░  ░░░░ ░ 
   ░   ░░░░░░░░░░░░░░░░░░▓██     ▓███████▓▓████████▓░░██░                   ░░      
        ░░▒░▓░░░░▒▒░░░░░▓▓    ░▓▒░░▓▓▓▓▓▓█▓░ ░░░▓▓░    ██                   ░░      
    ░░░░░░░░░░░░▒▒░░░░░██ ▓█▒ █▒░░▒█▓▓███▓▓███████▓▓▓▒  ▒ ▓░       ░     ░   ░▒▒█▓░ 
      ░░░░░▒▒░▓░░░▒▒░░▓█     ░▓░░░░░▓███████▓▓▓████████░ ▓ █   ░ ░ ░     ░░      ░▓ 
    ░░░░░░░▒░░░░░░░░░░▒  ▓  ░█▒  ░░░▓░▓███▓▓████████████░▓ █░  ░ ░           ░░░ ░░ 
       ░░░░░░░▒░░░▒▒░░█░▓    ░░  ░░  ░▓██▒▒▓▓░░░▒░▒▓████▒█ █▓ ░   ░░░░░░  ░░▒▓█░  ░ 
    ░░░░░░░░░░░▒░░░░▓░█   ░     ░ ░ ░░▓▓██▓░░▒▓▒░░▓▒░▒▓░░▓░██   ░░     ░░░░         
  ░░░░░░░░░▒▒░░▒░▒░█░ █▓    ░░      ░░███████░███████▓░ ░░   ░       ░              
  ░░░░░░░░░▒░░░░░▒▓░ █░ ▓█▒░ ░░    ░█████████████████▓  ░░  ░ ░       ░      ░   ░  
  ░ ░░  ░░░░░░░░░░▓  █  ▓    ░░  ░▒░   ▓████████████░▓▓░    ▒░         ░            
   ░░░░░░░░░░░░░░░▒▒ █ █ ░  ░░  ░            ░▓█████████    ░░ ░ ░ ░░               
 ░░░░░░░░░░░░░░░░░░░  ▒▒█    ▒██▓█▓██                      ░░░  ░                   
 ░░░░░░░░░░▒░░▒░░░░▒░██▒█    ░▓████▒▒░   █████         ░ ░▓░                        
 ░░░░░░░░░░░░░░░░░░░  ███    ░░▓███████████ ████████████ ░░  ░░                     
 ░░░░░░░░░░░░░░░ ░░░░          ░▓███████▓█▒ ██▓████████ ░▓ ░░   ░ ░░                
 ░░░░░░░░░░░░░░░░░░░░░ ░█        ░░▓▓    █  ██▒  █████▒  ░ ░░░  ░░░   ░░            
 ░░░░░░░░░░░░░░░░░░░   ██  ░▒         ▒█  ░█████   ░                ░░░░░░░         
  ░░░░░░▒░░░░░░░░  ░  █ █   ░   ░   █████░     ▓      ▒███████        ░             
  ░░ ░░░░░░░░░       ███  ░   ░░▓█░▓    ▓███   ░   ▓░░████████████▒      ░          
  ░░░░░░░░      ▒███ ████      ░░░░░  ▓▒    ░▓░▓█ ▓░ ███████▓█████████              
 ░░░░░░     ░███████▓██████▓       ▓█████░     ▓█   ████████ ▓█████▓█████           
 ░░░░    ███████████ █████████      ░▓▓███▓ ░▒▓▒   █░███████  ▓████████████         
      ███████████████ ███████████      ░▓█████   ████░██████  ░██████████████       
   ▓███████████████████████████████           ██████████████▓ ░████████████████     
 ████████████████████████████████████░░▒███▓░████████████████ ░█████████████████    
]]

dashboard.section.header.val = vim.split(logo, "\n")

function openNvimConfig()
	vim.cmd("lcd ~/stuff/repo/.dotfiles")
	vim.cmd("e ~/stuff/repo/.dotfiles/nvim/lua/ylniss/plugins.lua")
end

dashboard.section.buttons.val = {
	dashboard.button("space s f", " > Search file"),
	dashboard.button("space s p", " > Search repo"),
	dashboard.button("space s g", "⚡> Search text with grep"),
	dashboard.button("space s b", " > Search bookmarks"),
	dashboard.button("space ?", "� > Recently used files"),
	dashboard.button("space e", " > Explorer"),
	dashboard.button("n", " > New file", "<cmd>ene <BAR> startinsert <CR>"),
	dashboard.button("c", " > Nvim config", "<cmd>lua openNvimConfig()<CR>"),
	dashboard.button("l", "󰚥 > Lazy config", "<cmd>Lazy<CR>"),
	dashboard.button("m", "󱌣 > Mason config", "<cmd>Mason<CR>"),
	dashboard.button("q", "⏻ > Quit Neovim", "<cmd>qa<CR>"),
}

local function footer()
	return " 󰈈 󰈈 󰈈  WE SMOKE ACID BITCH! 󰈈 󰈈 󰈈 "
end

dashboard.section.footer.val = footer()

vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#ffff61", bg = "none" })
vim.api.nvim_set_hl(0, "DashboardButtons", { fg = "#FFA500", bg = "none" })

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "DashboardHeader"
dashboard.section.buttons.opts.hl = "DashboardButtons"

dashboard.opts.opts.noautocmd = true

require("alpha").setup(dashboard.opts)
