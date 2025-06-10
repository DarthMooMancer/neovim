vim.g.mapleader = " "
vim.o.mouse =  ""
vim.o.completeopt = "noselect"
vim.o.termguicolors = true
vim.o.wrap = false
vim.o.relativenumber = true
vim.o.scrolloff = 8
vim.o.shiftwidth = 4
vim.o.hlsearch = false
vim.o.swapfile = false
vim.o.showmode = false

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set("n", "<leader>ff", "gg=G")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "<leader>lg", "<Cmd>term lazygit<CR>")
vim.keymap.set("n", "<leader>he", "<Cmd>FzfLua helptags<CR>")
vim.keymap.set("n", "<leader><leader>", "<Cmd>FzfLua files<CR>")
vim.keymap.set("n", "<leader>ge", "<Cmd>FzfLua grep<CR>")
vim.keymap.set("n", "<leader>xx", "<Cmd>FzfLua diagnostics_workspace<CR>")

require("darthmoomancer.lazy")

vim.lsp.enable({ "lua_ls", "clangd" })
