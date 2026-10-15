-- Local, writable configuration. No plugin manager or external toolchain.
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>")
