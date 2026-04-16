local o = vim.o

for _, provider in ipairs({ "python3_provider" }) do
  vim.g["loaded_" .. provider] = nil
  vim.cmd("runtime " .. provider)
end

o.clipboard = ""
o.cursorlineopt = "both"
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
o.termguicolors = true
o.showtabline = 2
o.foldenable = true
o.foldmethod = "expr"
o.foldlevel = 99
o.conceallevel = 1
