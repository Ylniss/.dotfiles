-- ========================================================
-- LSP
-- Language server protocol configuration with Mason
-- ========================================================
return {
	"neovim/nvim-lspconfig",
	ft = { "dockerfile", "json", "jsonc", "yaml", "toml", "terraform", "lua" },
	cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		require("mason").setup({
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		})
		local servers = {
			dockerls = {},
			jsonls = {},
			yamlls = {},
			taplo = {},
			terraformls = {},
			gopls = {},
			lua_ls = {
				Lua = {
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
					diagnostics = {
						disable = { "missing-fields" },
						globals = { "vim", "require" },
					},
				},
			},
		}

		local uname = vim.uv.os_uname()
		local is_nixos = uname.sysname == "Linux" and uname.version:match("NixOS")
		local is_android = vim.uv.fs_stat(vim.fn.expand("~/storage/dcim/camera")) ~= nil

		if is_nixos or is_android then
			return
		end

		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(servers),
		})

		for server_name, server_settings in pairs(servers) do
			vim.lsp.config(server_name, { settings = server_settings })
		end
		vim.lsp.enable(vim.tbl_keys(servers))
		vim.lsp.enable("stylua", false)

		require("mason-tool-installer").setup({
			ensure_installed = {
				"stylua",
				"prettier",
				"taplo",
				"roslyn",
			},
		})
	end,
}
