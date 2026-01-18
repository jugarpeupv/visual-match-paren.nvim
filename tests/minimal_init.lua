-- Minimal init file for testing
vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/plenary.nvim")

-- Setup plugin
require("visual-match-paren").setup()
