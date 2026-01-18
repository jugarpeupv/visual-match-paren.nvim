local M = {}

local namespace = vim.api.nvim_create_namespace("visual-match-paren")

M.config = {
  highlight_group = "MatchParen",
  enabled = true,
}

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
  })
end

function M.clear_highlight()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
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
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor_pos[1]
  
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  
  local last_selected_line = math.max(start_line, end_line)
  
  local line = vim.api.nvim_buf_get_lines(bufnr, last_selected_line - 1, last_selected_line, false)[1]
  
  if not line then
    return
  end
  
  local trimmed = line:match("^%s*(.-)%s*$")
  if not trimmed or not trimmed:match("{$") then
    return
  end
  
  local open_brace_col = line:find("{[^{]*$")
  if not open_brace_col then
    return
  end
  
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, {last_selected_line, open_brace_col - 1})
  
  local ok, match_pos = pcall(vim.fn.searchpairpos, "{", "", "}", "nW", "", 0, 100)
  
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  
  if ok and match_pos and match_pos[1] > 0 and match_pos[2] > 0 then
    local match_line = match_pos[1]
    local match_col = match_pos[2]
    
    vim.api.nvim_buf_add_highlight(
      bufnr,
      namespace,
      M.config.highlight_group,
      match_line - 1,
      match_col - 1,
      match_col
    )
  end
end

function M.toggle()
  M.config.enabled = not M.config.enabled
  if not M.config.enabled then
    M.clear_highlight()
  end
end

return M
