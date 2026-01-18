if vim.g.loaded_visual_match_paren then
  return
end
vim.g.loaded_visual_match_paren = 1

vim.api.nvim_create_user_command("VisualMatchParenToggle", function()
  require("visual-match-paren").toggle()
end, {})
