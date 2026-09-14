-- ========================================================
-- MiniDiff
-- Git gutter signs, hunk operations and inline diff overlay
-- ========================================================
return {
	"nvim-mini/mini.diff",
	event = "BufReadPre",
	config = function()
		local minidiff = require("mini.diff")
		local index_source = minidiff.gen_source.git()

		-- Reference is git index normally and HEAD while overlay is on, so overlay shows staged changes too.
		local overlay_on = false

		local source = {
			name = "git",
			attach = function(buf)
				if not overlay_on then
					return index_source.attach(buf)
				end
				local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
				if not path then
					return false
				end
				local cmd = { "git", "show", "HEAD:./" .. vim.fn.fnamemodify(path, ":t") }
				vim.system(cmd, { cwd = vim.fn.fnamemodify(path, ":h") }, function(res)
					vim.schedule(function()
						-- Result can arrive after the buffer is wiped or overlay is turned off again
						if not overlay_on or not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						minidiff.set_ref_text(buf, res.code == 0 and res.stdout:gsub("\r\n", "\n") or nil)
					end)
				end)
			end,
			detach = index_source.detach,
			apply_hunks = function(buf, hunks)
				-- Patch is built from reference text; applying a HEAD-based patch to index can silently corrupt it
				if overlay_on then
					vim.notify("Turn off git diff overlay (<leader>gd) to stage hunks", vim.log.levels.WARN)
					return
				end
				index_source.apply_hunks(buf, hunks)
			end,
		}

		minidiff.setup({
			source = source,
			view = {
				style = "sign",
				signs = { add = "+", change = "~", delete = "_" },
			},
			-- Default `gh` textobject stays: normal mode hunk keymaps use it as the operator target.
			-- `[h`/`]h` would make `[`/`]` (buffer switching) wait for timeout.
			mappings = {
				apply = "",
				reset = "",
				goto_first = "",
				goto_prev = "",
				goto_next = "",
				goto_last = "",
			},
		})

		vim.keymap.set("n", "<leader>ghs", function()
			return minidiff.operator("apply") .. "gh"
		end, { expr = true, remap = true, desc = "git stage hunk" })
		vim.keymap.set("n", "<leader>ghr", function()
			return minidiff.operator("reset") .. "gh"
		end, { expr = true, remap = true, desc = "git reset hunk" })
		vim.keymap.set("v", "<leader>ghs", function()
			return minidiff.operator("apply")
		end, { expr = true, desc = "stage git hunk" })
		vim.keymap.set("v", "<leader>ghr", function()
			return minidiff.operator("reset")
		end, { expr = true, desc = "reset git hunk" })
		vim.keymap.set("n", "<leader>ghS", function()
			minidiff.do_hunks(0, "apply")
		end, { desc = "git Stage buffer" })
		vim.keymap.set("n", "<leader>gR", function()
			minidiff.do_hunks(0, "reset")
		end, { desc = "git Reset buffer" })
		-- Start lines of hunk ranges; contiguous hunks form one range like in `MiniDiff.goto_hunk()`
		local function hunk_starts(buf)
			local data = minidiff.get_buf_data(buf)
			if not data then
				return {}
			end
			local starts, range_end = {}, -1
			for _, h in ipairs(data.hunks) do
				local from = math.max(h.buf_start, 1)
				if from > range_end + 1 then
					table.insert(starts, from)
				end
				range_end = math.max(range_end, from, h.buf_start + h.buf_count - 1)
			end
			return starts
		end

		-- Buffer without reference text (not loaded yet) has no hunks, so ask git about the file on disk
		local function has_git_changes(buf)
			local data = minidiff.get_buf_data(buf)
			if data and data.ref_text then
				return #data.hunks > 0
			end
			local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
			if not path then
				return false
			end
			local name = vim.fn.fnamemodify(path, ":t")
			local cmd = overlay_on and { "git", "diff", "--quiet", "HEAD", "--", name }
				or { "git", "diff", "--quiet", "--", name }
			-- Exit code 1 means differences; errors like "not a git repo" exit with a higher code
			return vim.system(cmd, { cwd = vim.fn.fnamemodify(path, ":h") }):wait().code == 1
		end

		local function jump_to_line(line)
			vim.cmd("normal! " .. line .. "G^zvzz")
		end

		-- Enter buffer and jump to its first/last hunk range; false when it has none
		local function jump_to_buffer_hunk(buf, forward)
			if not has_git_changes(buf) then
				return false
			end
			vim.api.nvim_set_current_buf(buf)
			-- Freshly loaded buffer gets its hunks asynchronously
			vim.wait(1000, function()
				return #hunk_starts(buf) > 0
			end)
			local starts = hunk_starts(buf)
			if #starts == 0 then
				return false
			end
			jump_to_line(forward and starts[1] or starts[#starts])
			return true
		end

		-- Go to the next or previous hunk range. If this buffer has no more ranges, continue in the nearest listed buffer with changes.
		local function jump_hunk(forward)
			local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
			local starts = hunk_starts(buf)
			local target
			if forward then
				target = vim.iter(starts):find(function(start)
					return start > line
				end)
			else
				target = vim.iter(starts):rfind(function(start)
					return start < line
				end)
			end
			if target then
				return jump_to_line(target)
			end

			local bufs = vim.tbl_map(function(info)
				return info.bufnr
			end, vim.fn.getbufinfo({ buflisted = 1 }))
			local n, step = #bufs, forward and 1 or -1
			local cur_index = vim.fn.index(bufs, buf) + 1
			-- Unlisted current buffer (e.g. help) starts the scan from the list edge
			if cur_index == 0 and not forward then
				cur_index = n + 1
			end
			-- Last candidate is the current buffer itself, so a single changed buffer wraps around
			for k = 1, n do
				if jump_to_buffer_hunk(bufs[(cur_index - 1 + k * step) % n + 1], forward) then
					return
				end
			end
			vim.api.nvim_set_current_buf(buf)
			vim.notify("No git hunks in listed buffers", vim.log.levels.INFO)
		end

		vim.keymap.set("n", "<C-n>", function()
			for _ = 1, vim.v.count1 do
				jump_hunk(true)
			end
		end, { desc = "go to next git hunk, continue in next buffers" })
		vim.keymap.set("n", "<C-p>", function()
			for _ = 1, vim.v.count1 do
				jump_hunk(false)
			end
		end, { desc = "go to previous git hunk, continue in previous buffers" })

		vim.keymap.set("n", "<leader>gd", function()
			overlay_on = not overlay_on
			-- Re-enable so every buffer attaches the source again with the new reference
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if minidiff.get_buf_data(buf) then
					minidiff.disable(buf)
					minidiff.enable(buf)
				end
			end
		end, { desc = "toggle git diff overlay against HEAD in all buffers" })

		-- Overlay state is per buffer and resets on enable; sync it on every diff update.
		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniDiffUpdated",
			callback = function(ev)
				if minidiff.get_buf_data(ev.buf).overlay ~= overlay_on then
					minidiff.toggle_overlay(ev.buf)
				end
			end,
		})
	end,
}
