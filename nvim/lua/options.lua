require "nvchad.options"

-- add yours here!

local o = vim.o
local enable_providers = {
    "python3_provider",
}

for _, plugin in pairs(enable_providers) do
    vim.g["loaded_" .. plugin] = nil
    vim.cmd("runtime " .. plugin)
end
o.clipboard = ""
o.cursorlineopt = "both" -- to enable cursorline!
o.smartindent = true
o.smarttab = true
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4

o.ignorecase = true
o.cursorline = true
o.timeout = true
o.timeoutlen = 1000
o.ttimeoutlen = 0
o.expandtab = true
o.linebreak = true
o.autoread = true
o.autochdir = true
o.autowriteall = true
o.breakindent = true
o.wrap = true
o.textwidth = 180
o.ruler = true
o.relativenumber = true
o.number = true
o.whichwrap = ""
o.foldenable = true
o.foldmethod = "expr"
o.foldlevel = 99
