-- Highlight other instances of the symbol under the cursor via LSP.
-- Only attaches for clients that support textDocument/documentHighlight.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client or not client:supports_method("textDocument/documentHighlight") then
			return
		end

		local bufnr = args.buf
		local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })

		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})

		vim.api.nvim_create_autocmd("LspDetach", {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.clear_references()
				pcall(vim.api.nvim_del_augroup_by_name, "LspDocumentHighlight_" .. bufnr)
			end,
		})
	end,
})
