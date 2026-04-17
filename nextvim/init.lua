vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.python3_host_prog = "/usr/bin/python"

local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.rtp:prepend(config_dir)
package.path = config_dir .. "/lua/?.lua;" .. config_dir .. "/lua/?/init.lua;" .. package.path

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("core.options")
require("core.runtime")
require("core.autocmds")
require("core.highlight")
require("lazy").setup("plugins", require("configs.lazy"))
require("configs.theme").setup_persist()
vim.schedule(function()
  require("configs.theme").apply_startup_theme()
end)
require("core.keymaps")
