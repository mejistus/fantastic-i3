vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  command = "silent! loadview",
})

vim.api.nvim_create_autocmd("BufWinLeave", {
  pattern = "*",
  command = "silent! mkview",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.keymap.set("n", "<leader>lw", "<cmd>VimtexCountWords!<CR>", { buffer = true, silent = true })
  end,
})
