--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local lsp_keymap = function(keys, func, desc)
		if desc then
			desc = "lsp: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	lsp_keymap("<leader>r", "<cmd>Lspsaga rename<CR>", "rename")
	lsp_keymap("<A-h>", "<cmd>Lspsaga code_action<CR>", "code action") -- with .ahk script it is also <C-.> (powershell fix)

	local telescope = require("telescope.builtin")

	lsp_keymap("gD", vim.lsp.buf.declaration, "goto declaration")
	lsp_keymap("gd", telescope.lsp_definitions, "goto definition")
	lsp_keymap("gr", telescope.lsp_references, "goto references")
	lsp_keymap("gI", telescope.lsp_implementations, "goto implementation")
	lsp_keymap("<leader>D", telescope.lsp_type_definitions, "type definition")
end

require("mason").setup()
require("mason-lspconfig").setup()

-- Enable the following language servers
local servers = {
	dockerls = {},
	jsonls = {},
	tsserver = {},
	html = { filetypes = { "html" } },
	powershell_es = {},
	omnisharp = {},
	yamlls = {},
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

-- Setup neovim lua configuration
require("neodev").setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = servers[server_name],
			filetypes = (servers[server_name] or {}).filetypes,
		})
	end,
})

require("mason-tool-installer").setup({
	ensure_installed = {
		-- formatters
		"stylua",
		"yamlfmt",
		"prettier",
		"prettierd",
		"mdformat",
		"csharpier",
	},
})
