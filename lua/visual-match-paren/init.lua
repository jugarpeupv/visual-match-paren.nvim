local M = {}

local namespace = vim.api.nvim_create_namespace("visual-match-paren")
local scope_namespace = vim.api.nvim_create_namespace("visual-match-paren-scope")

M.config = {
	highlight_group = "MatchParen",
	scope_highlight_group = "MatchParen",
	enabled = true,
	scope_enabled = true,
	scope_textobject = "I", -- Text object for inner scope
	incremental_selection = {
		enabled = true,
		keymaps = {
			increment = "<Tab>",
			decrement = "<S-Tab>",
		},
	},
}

-- Track previous selection for toggle behavior
local last_scope_selection = nil

-- Stack to track incremental selections (for decrementing)
local selection_stack = {}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_autocmd("ModeChanged", {
		pattern = "*:[vV\x16]*",
		callback = function()
			M.highlight_matching_brace()
		end,
	})

	vim.api.nvim_create_autocmd("CursorMoved", {
		pattern = "*",
		callback = function()
			if vim.fn.mode():match("[vV\x16]") then
				M.highlight_matching_brace()
			else
				M.clear_highlight()
			end
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		pattern = "[vV\x16]*:*",
		callback = function()
			M.clear_highlight()
		end,
		nested = false,
	})

	-- Setup text object for scope selection
	if M.config.scope_textobject and M.config.scope_textobject ~= "" then
		vim.keymap.set({ "x", "o" }, M.config.scope_textobject, function()
			M.select_scope()
		end, { desc = "Select inner scope" })
	end

	-- Setup incremental selection keymaps
	if M.config.incremental_selection.enabled then
		if M.config.incremental_selection.keymaps.increment and M.config.incremental_selection.keymaps.increment ~= "" then
			vim.keymap.set("x", M.config.incremental_selection.keymaps.increment, function()
				M.increment_selection()
			end, { desc = "Increment node selection" })
		end
		if M.config.incremental_selection.keymaps.decrement and M.config.incremental_selection.keymaps.decrement ~= "" then
			vim.keymap.set("x", M.config.incremental_selection.keymaps.decrement, function()
				M.decrement_selection()
			end, { desc = "Decrement node selection" })
		end
	end
end

function M.clear_highlight()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
	vim.api.nvim_buf_clear_namespace(bufnr, scope_namespace, 0, -1)
end

local function get_node_at_line(line_number)
	local row = line_number - 1
	local col = 0

	local ok, root_parser = pcall(vim.treesitter.get_parser, 0, nil, {})
	if not ok or not root_parser then
		return
	end

	root_parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
	local lang_tree = root_parser:language_for_range({ row, col, row, col })

	return lang_tree:named_node_for_range({ row, col, row, col }, { ignore_injections = false })
end

local function get_inner_scope_range(node, line_number)
	if not node then
		return nil
	end

	local node_type = node:type()
	local start_row, _, end_row, _ = node:range()
	
	-- Check if the current node itself is a scope-defining node (function, class, etc.)
	-- and the selected line is at the start of this node
	if start_row == line_number then
		-- For functions/classes, we want the entire node range (including closing brace)
		-- not just the body
		if node_type:match("function") or 
		   node_type:match("class") or
		   node_type:match("method") then
			-- Use the full node range which includes the closing brace
			if end_row > start_row then
				return start_row, end_row
			end
		end
		
		-- Look for a body/block child node (for other constructs)
		for child in node:iter_children() do
			local child_type = child:type()
			-- Match common body/block node types across languages
			if child_type:match("body") or 
			   child_type:match("block") or 
			   child_type == "statement_block" then
				local child_start_row, _, child_end_row, _ = child:range()
				if child_end_row > child_start_row then
					return child_start_row, child_end_row
				end
			end
		end
		
		-- If this node spans multiple lines and starts at the selected line,
		-- use the node's range itself
		if end_row > start_row then
			return start_row, end_row
		end
	end

	-- Try to find a child node that represents the content/value
	-- This works for YAML block mappings where we want the value part
	for child in node:iter_children() do
		local child_start_row, _, child_end_row, _ = child:range()
		-- If child starts after the selected line, it's likely the nested content
		if child_start_row >= line_number then
			return child_start_row, child_end_row
		end
	end

	-- Fallback: use the node's own range if it spans multiple lines
	if end_row > start_row and start_row == line_number - 1 then
		-- Return range excluding the first line (the key line itself)
		return start_row + 1, end_row
	end

	return nil
end

local function get_parent_scope_range(node, line_number)
	if not node then
		return nil
	end

	local parent = node:parent()
	if not parent then
		return nil
	end

	-- Find a sibling or parent scope that contains this line
	local start_row, _, end_row, _ = parent:range()
	if end_row > start_row then
		return start_row, end_row
	end

	return nil
end

local function highlight_scope(bufnr, start_line, end_line)
	for line = start_line, end_line do
		vim.api.nvim_buf_set_extmark(bufnr, scope_namespace, line - 1, 0, {
			number_hl_group = M.config.scope_highlight_group,
			priority = 100,
		})
	end
end

function M.highlight_matching_brace()
	if not M.config.enabled then
		return
	end

	M.clear_highlight()

	local mode = vim.fn.mode()
	if not mode:match("[vV\x16]") then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.fn.getpos("v")

	local first_selected_line = start_pos[2]

	local line = vim.api.nvim_buf_get_lines(bufnr, first_selected_line - 1, first_selected_line, false)[1]

	if not line then
		return
	end

	local trimmed = line:match("^%s*(.-)%s*$")
	if not trimmed then
		return
	end

	local saved_cursor = vim.api.nvim_win_get_cursor(0)

	-- Try to highlight scope using treesitter
	if M.config.scope_enabled then
		local node = get_node_at_line(first_selected_line)
		if node then
			local start_row, end_row = get_inner_scope_range(node, first_selected_line - 1)
			
			-- If no inner scope, try parent scope
			if not start_row or not end_row or end_row <= start_row then
				start_row, end_row = get_parent_scope_range(node, first_selected_line - 1)
			end
			
			if start_row and end_row and end_row > start_row then
				-- Ensure the range is within buffer bounds
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				start_row = math.max(0, start_row)
				end_row = math.min(end_row, line_count - 1)
				
				if end_row > start_row then
					-- treesitter ranges are 0-indexed with exclusive end
					-- Example: [63, 84) means rows 63-83 inclusive (0-indexed) = lines 64-84 (1-indexed)
					-- But since we check end_col, if range is [63:0, 84:1], it includes row 84 col 0
					-- For line-based highlighting, we treat end_row as the last line to check
					-- So: start_line = start_row + 1, end_line = end_row + 1
					highlight_scope(bufnr, start_row + 1, end_row + 1)
				end
			end
		end
	end

	-- Check if line ends with opening brace
	if trimmed:match("{$") then
		local open_brace_col = line:find("{[^{]*$")
		if not open_brace_col then
			return
		end

		vim.api.nvim_win_set_cursor(0, { first_selected_line, open_brace_col - 1 })

		local ok, match_pos = pcall(vim.fn.searchpairpos, "{", "", "}", "nW", "", 0, 100)

		vim.api.nvim_win_set_cursor(0, saved_cursor)

		if ok and match_pos and match_pos[1] > 0 and match_pos[2] > 0 then
			local match_line = match_pos[1]
			local match_col = match_pos[2]

			vim.api.nvim_buf_set_extmark(bufnr, namespace, first_selected_line - 1, open_brace_col - 1, {
				end_col = open_brace_col,
				hl_group = M.config.highlight_group,
			})

			vim.api.nvim_buf_set_extmark(bufnr, namespace, match_line - 1, match_col - 1, {
				end_col = match_col,
				hl_group = M.config.highlight_group,
			})
		end
	-- Check if line starts with closing brace
	elseif trimmed:match("^}") then
		local close_brace_col = line:find("}")
		if not close_brace_col then
			return
		end

		vim.api.nvim_win_set_cursor(0, { first_selected_line, close_brace_col - 1 })

		local ok, match_pos = pcall(vim.fn.searchpairpos, "{", "", "}", "nbW", "", 0, 100)

		vim.api.nvim_win_set_cursor(0, saved_cursor)

		if ok and match_pos and match_pos[1] > 0 and match_pos[2] > 0 then
			local match_line = match_pos[1]
			local match_col = match_pos[2]

			vim.api.nvim_buf_set_extmark(bufnr, namespace, first_selected_line - 1, close_brace_col - 1, {
				end_col = close_brace_col,
				hl_group = M.config.highlight_group,
			})

			vim.api.nvim_buf_set_extmark(bufnr, namespace, match_line - 1, match_col - 1, {
				end_col = match_col,
				hl_group = M.config.highlight_group,
			})
		end
	-- Check if line ends with opening bracket
	elseif trimmed:match("%[$") then
		local open_bracket_col = line:find("%[[^%[]*$")
		if not open_bracket_col then
			return
		end

		vim.api.nvim_win_set_cursor(0, { first_selected_line, open_bracket_col - 1 })

		local ok, match_pos = pcall(vim.fn.searchpairpos, "\\[", "", "\\]", "nW", "", 0, 100)

		vim.api.nvim_win_set_cursor(0, saved_cursor)

		if ok and match_pos and match_pos[1] > 0 and match_pos[2] > 0 then
			local match_line = match_pos[1]
			local match_col = match_pos[2]

			vim.api.nvim_buf_set_extmark(bufnr, namespace, first_selected_line - 1, open_bracket_col - 1, {
				end_col = open_bracket_col,
				hl_group = M.config.highlight_group,
			})

			vim.api.nvim_buf_set_extmark(bufnr, namespace, match_line - 1, match_col - 1, {
				end_col = match_col,
				hl_group = M.config.highlight_group,
			})
		end
	-- Check if line starts with closing bracket
	elseif trimmed:match("^%]") then
		local close_bracket_col = line:find("%]")
		if not close_bracket_col then
			return
		end

		vim.api.nvim_win_set_cursor(0, { first_selected_line, close_bracket_col - 1 })

		local ok, match_pos = pcall(vim.fn.searchpairpos, "\\[", "", "\\]", "nbW", "", 0, 100)

		vim.api.nvim_win_set_cursor(0, saved_cursor)

		if ok and match_pos and match_pos[1] > 0 and match_pos[2] > 0 then
			local match_line = match_pos[1]
			local match_col = match_pos[2]

			vim.api.nvim_buf_set_extmark(bufnr, namespace, first_selected_line - 1, close_bracket_col - 1, {
				end_col = close_bracket_col,
				hl_group = M.config.highlight_group,
			})

			vim.api.nvim_buf_set_extmark(bufnr, namespace, match_line - 1, match_col - 1, {
				end_col = match_col,
				hl_group = M.config.highlight_group,
			})
		end
	end
end

function M.toggle()
	M.config.enabled = not M.config.enabled
	if not M.config.enabled then
		M.clear_highlight()
	end
end

function M.select_scope()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor_pos[1]

	-- Check if we're toggling back to previous selection
	local mode = vim.api.nvim_get_mode().mode
	if mode:match("[vV\x16]") and last_scope_selection then
		local visual_start = vim.fn.getpos("v")
		local visual_end = vim.api.nvim_win_get_cursor(0)
		local start_line = math.min(visual_start[2], visual_end[1])
		local end_line = math.max(visual_start[2], visual_end[1])

		-- If current selection matches last scope selection, restore previous
		if last_scope_selection.scope_start == start_line and last_scope_selection.scope_end == end_line then
			vim.api.nvim_win_set_cursor(0, { last_scope_selection.prev_start, 0 })
			vim.cmd("normal! o")
			vim.api.nvim_win_set_cursor(0, { last_scope_selection.prev_end, 0 })
			last_scope_selection = nil
			return
		end
	end

	local node = get_node_at_line(current_line)
	if not node then
		return
	end

	-- Try to get inner scope first
	local start_row, end_row = get_inner_scope_range(node, current_line - 1)
	
	-- If no inner scope, try parent scope
	if not start_row or not end_row or end_row <= start_row then
		start_row, end_row = get_parent_scope_range(node, current_line - 1)
	end

	if not start_row or not end_row or end_row <= start_row then
		return
	end

	-- Ensure the range is within buffer bounds
	local bufnr = vim.api.nvim_get_current_buf()
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	start_row = math.max(0, start_row)
	end_row = math.min(end_row, line_count - 1)

	if end_row <= start_row then
		return
	end

	-- Save previous selection if in visual mode
	local prev_start, prev_end = current_line, current_line
	if mode:match("[vV\x16]") then
		local visual_start = vim.fn.getpos("v")
		local visual_end = vim.api.nvim_win_get_cursor(0)
		prev_start = math.min(visual_start[2], visual_end[1])
		prev_end = math.max(visual_start[2], visual_end[1])
	end

	-- Enter visual line mode if not already in visual mode
	if not mode:match("[vV\x16]") then
		vim.cmd("normal! V")
	end

	-- Select from start to end line (convert to 1-indexed)
	-- treesitter ranges are 0-indexed with exclusive end
	-- For line highlighting, we include the end_row
	local start_line = start_row + 1
	local end_line = end_row + 1
	
	vim.api.nvim_win_set_cursor(0, { start_line, 0 })
	vim.cmd("normal! o")
	vim.api.nvim_win_set_cursor(0, { end_line, 0 })

	-- Save this selection for toggle
	last_scope_selection = {
		scope_start = start_line,
		scope_end = end_line,
		prev_start = prev_start,
		prev_end = prev_end,
	}
end

local function get_visual_selection_range()
	local visual_start = vim.fn.getpos("v")
	local visual_end = vim.api.nvim_win_get_cursor(0)
	local start_line = math.min(visual_start[2], visual_end[1])
	local end_line = math.max(visual_start[2], visual_end[1])
	local start_col = visual_start[3] - 1
	local end_col = visual_end[2]
	return start_line, start_col, end_line, end_col
end

local function get_node_at_range(start_line, start_col, end_line, end_col)
	local start_row = start_line - 1
	local end_row = end_line - 1

	local ok, root_parser = pcall(vim.treesitter.get_parser, 0, nil, {})
	if not ok or not root_parser then
		return nil
	end

	root_parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
	local lang_tree = root_parser:language_for_range({ start_row, start_col, end_row, end_col })

	return lang_tree:named_node_for_range({ start_row, start_col, end_row, end_col }, { ignore_injections = false })
end

function M.increment_selection()
	if not M.config.incremental_selection.enabled then
		return
	end

	local mode = vim.api.nvim_get_mode().mode
	if not mode:match("[vV\x16]") then
		return
	end

	local start_line, start_col, end_line, end_col = get_visual_selection_range()
	
	-- Save current selection to stack
	table.insert(selection_stack, {
		start_line = start_line,
		start_col = start_col,
		end_line = end_line,
		end_col = end_col,
	})

	local node = get_node_at_range(start_line, start_col, end_line, end_col)
	if not node then
		-- If no node found, remove from stack
		table.remove(selection_stack)
		return
	end

	-- Get parent node
	local parent = node:parent()
	if not parent then
		-- If no parent, remove from stack
		table.remove(selection_stack)
		return
	end

	local p_start_row, p_start_col, p_end_row, p_end_col = parent:range()
	
	-- Ensure the parent is actually larger than current selection
	if p_start_row >= start_line - 1 and p_end_row <= end_line - 1 then
		-- Parent is not larger, remove from stack
		table.remove(selection_stack)
		return
	end

	-- Ensure the range is within buffer bounds
	local bufnr = vim.api.nvim_get_current_buf()
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	p_start_row = math.max(0, p_start_row)
	p_end_row = math.min(p_end_row, line_count - 1)

	-- Select the parent node range
	local new_start_line = p_start_row + 1
	local new_end_line = p_end_row + 1

	-- In visual mode, set cursor to start of parent range
	vim.api.nvim_win_set_cursor(0, { new_start_line, p_start_col })
	
	-- Toggle to other end of selection
	vim.cmd("normal! o")
	
	-- Move to end of parent range
	local end_line_text = vim.api.nvim_buf_get_lines(bufnr, p_end_row, p_end_row + 1, false)[1] or ""
	local final_col = math.min(p_end_col, #end_line_text)
	vim.api.nvim_win_set_cursor(0, { new_end_line, final_col })
end

function M.decrement_selection()
	if not M.config.incremental_selection.enabled then
		return
	end

	local mode = vim.api.nvim_get_mode().mode
	if not mode:match("[vV\x16]") then
		return
	end

	-- Pop from selection stack
	if #selection_stack == 0 then
		return
	end

	local prev_selection = table.remove(selection_stack)
	
	-- Restore previous selection
	vim.api.nvim_win_set_cursor(0, { prev_selection.start_line, prev_selection.start_col })
	vim.cmd("normal! o")
	vim.api.nvim_win_set_cursor(0, { prev_selection.end_line, prev_selection.end_col })
end

return M
