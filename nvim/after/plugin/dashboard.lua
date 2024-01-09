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

 dashboard.section.buttons.val = {
   dashboard.button("space s f", "  Find file"),
   dashboard.button("space s g", "  Find text with grep"),
   dashboard.button("space ?",   "  Recently used files"),
   dashboard.button("n",         "  New file", ":ene <BAR> startinsert <CR>"),
   dashboard.button("space e",   "  Explorer"),
   dashboard.button("c",         "  Nvim config", ":e ~/stuff/repo/.dotfiles/nvim/ylniss/plugins.lua<CR>"),
   dashboard.button("l",         "󰚥  Lazy config", ":Lazy<CR>"),
   dashboard.button("m",         "󱌣  Mason config", ":Mason<CR>"),
   dashboard.button("q",         "  Quit Neovim", ":qa<CR>"),
}

local function footer()
 return "We smoke acid bitch!"
end

dashboard.section.footer.val = footer()

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true

require('alpha').setup(dashboard.opts)
