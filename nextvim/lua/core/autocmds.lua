local view_group = vim.api.nvim_create_augroup("PersistentViews", { clear = true })

local function can_persist_view(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= ""
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = view_group,
  pattern = "*",
  callback = function(args)
    if can_persist_view(args.buf) then
      vim.cmd("silent! loadview")
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost" }, {
  group = view_group,
  pattern = "*",
  callback = function(args)
    if can_persist_view(args.buf) then
      vim.cmd("silent! mkview")
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.keymap.set("n", "<leader>lw", "<cmd>VimtexCountWords!<CR>", { buffer = true, silent = true })
  end,
})

-- Ensure commentstring is set for filetypes that lack it,
-- so Comment.nvim (gcc/gc) never gets nil.
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "conf", "config", "cfg", "ini", "sshconfig", "sshdconfig",
    "tmux", "fstab", "crontab", "samba", "resolv",
    "toml", "dosini", "desktop", "xdefaults",
    "gitconfig", "hgrc",
    "bash", "zsh", "sh",
    "i3config", "swayconfig", "hypr",
  },
  callback = function()
    if vim.bo.commentstring == "" or vim.bo.commentstring == nil then
      vim.bo.commentstring = "# %s"
    end
  end,
})
