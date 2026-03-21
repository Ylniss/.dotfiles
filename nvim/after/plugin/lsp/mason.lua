vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local bufnr = ev.buf
		local lsp_keymap = function(keys, func, desc)
			if desc then
				desc = "lsp: " .. desc
			end
			vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
		end

		lsp_keymap("<leader>r", vim.lsp.buf.rename, "rename")
		lsp_keymap("<C-.>", vim.lsp.buf.code_action, "code action") -- with .ahk script it is also <C-.> (powershell fix)

		local fzf = require("fzf-lua")

		lsp_keymap("gD", vim.lsp.buf.declaration, "goto declaration")
		lsp_keymap("gd", fzf.lsp_definitions, "goto definition")
		lsp_keymap("gr", fzf.lsp_references, "goto references")
		lsp_keymap("gI", fzf.lsp_implementations, "goto implementation")
		lsp_keymap("<leader>D", fzf.lsp_typedefs, "type definition")
	end,
})

require("mason").setup()
require("mason-lspconfig").setup()

-- Enable the following language servers
local servers = {
	dockerls = {},
	jsonls = {},
	yamlls = {},
	taplo = {},
	terraformls = {},
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
			diagnostics = {
				-- Ignore Lua_LS's noisy `missing-fields` warnings
				disable = { "missing-fields" },
				globals = { "vim, require" },
			},
		},
	},
}

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

local function is_android()
	local camera_path = vim.fn.expand("~/storage/dcim/camera")
	return vim.uv.fs_stat(camera_path) ~= nil
end

local uname = vim.uv.os_uname()
local is_nixos = uname.sysname == "Linux" and uname.version:match("NixOS")

-- Check if the OS is NixOS or Android - they have to handle lsp and formatters installation itslef
if not is_nixos and not is_android() then
	mason_lspconfig.setup({
		ensure_installed = vim.tbl_keys(servers),
	})

	for server_name, server_settings in pairs(servers) do
		vim.lsp.config(server_name, {
			settings = server_settings,
			filetypes = (server_settings or {}).filetypes,
		})
	end
	vim.lsp.enable(vim.tbl_keys(servers))
	vim.lsp.enable("stylua", false)

	require("mason-tool-installer").setup({
		ensure_installed = {
			"stylua",
			"yamlfmt",
			"prettier",
			"mdformat",
			"taplo",
		},
	})
end
