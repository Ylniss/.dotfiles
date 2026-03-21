require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-n>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<C-d>"] = { "scroll_documentation_down" },
		["<C-f>"] = { "scroll_documentation_up" },
		["<A-a>"] = { "show" },
		["<CR>"] = { "accept", "fallback" },
		["<Esc>"] = { "cancel", "fallback" },
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
	},

	completion = {
		list = {
			selection = { preselect = true, auto_insert = false },
		},
		documentation = {
			auto_show = true,
		},
	},

	sources = {
		default = { "lazydev", "lsp", "path", "snippets" },
		providers = {
			lazydev = {
				name = "LazyDev",
				module = "lazydev.integrations.blink",
				score_offset = 100,
			},
		},
	},
})
