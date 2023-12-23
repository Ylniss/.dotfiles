require("ylniss")

-- Configure LSP 
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local lsp_keymap = function(keys, func, desc)
    if desc then
      desc = 'lsp: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  lsp_keymap('<leader>r', vim.lsp.buf.rename, 'rename')
  lsp_keymap('<leader>ca', vim.lsp.buf.code_action, 'code action')

  local telescope = require('telescope.builtin')

  lsp_keymap('gD', vim.lsp.buf.declaration, 'goto declaration')
  lsp_keymap('gd', telescope.lsp_definitions, 'goto definition')
  lsp_keymap('gr', telescope.lsp_references, 'goto references')
  lsp_keymap('gI', telescope.lsp_implementations, 'goto implementation')
  lsp_keymap('<leader>D', telescope.lsp_type_definitions, 'type definition')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'format current buffer with LSP' })
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },

  powershell_es = {},
  omnisharp = { filetypes = { "cs", "csx" } },
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
      diagnostics = { disable = { 'missing-fields' } },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
