local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)
vim.opt.mouse =  ""
vim.opt.completeopt = "noselect"
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.hlsearch = false
vim.opt.swapfile = false

vim.g.mapleader = " "
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set("n", "<leader>ff", "gg=G")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CR>:cclose<CR>", { noremap = true, silent = true })
  end,
})

vim.keymap.set("n", "<leader><leader>", function()
  local cwd = vim.fn.getcwd()
  local all_paths = vim.fn.globpath(cwd, "**", 0, 1)  -- get all paths recursively

  local files = {}
  for _, path in ipairs(all_paths) do
    if vim.fn.isdirectory(path) == 0 then  -- 0 means it's not a directory (i.e., a file)
      table.insert(files, path)
    end
  end

  if #files == 0 then
    print("No files found")
    return
  end

  local qf_list = {}
  for _, f in ipairs(files) do
    table.insert(qf_list, { filename = f, lnum = 1, col = 1, text = f })
  end

  vim.fn.setqflist(qf_list, 'r')
  vim.cmd("copen")
end, { desc = "Open files in quickfix list" })

vim.keymap.set("n", "<leader>xc", "<Cmd>cclose<CR>")
vim.keymap.set("n", "<leader>xg", function()
  local input = vim.fn.input("Grep for: ")
  if input ~= "" then
    vim.cmd("silent! grep " .. vim.fn.shellescape(input) .. " | cwindow")
  end
end)

vim.keymap.set("n", "<leader>xx", function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = "Show diagnostics in quickfix" })


require("lazy").setup("darthmoomancer.plugins")
require("everforest").setup({ transparent_background_level = 2 })
vim.cmd.colorscheme('everforest')

vim.lsp.enable({ "lua_ls", "clangd" })
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" }
			}
		}
	}
})
