-- Minimal init file for testing
vim.opt.runtimepath:append(".")

-- Install plenary.nvim if not found
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim.git",
    plenary_path,
  })
end

vim.opt.runtimepath:prepend(plenary_path)

-- Load plenary's plugin files
vim.cmd("runtime! plugin/plenary.vim")

-- Setup plugin
require("visual-match-paren").setup()
