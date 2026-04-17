local M = {}

local theme_file = vim.fn.stdpath("state") .. "/theme.txt"
local default_theme = "tokyonight"

local function save_theme(name)
  if not name or name == "" then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p")
  vim.fn.writefile({ name }, theme_file)
end

local function load_theme()
  local ok, lines = pcall(vim.fn.readfile, theme_file)
  if ok and lines and #lines > 0 and lines[1] ~= "" then
    return lines[1]
  end
  return default_theme
end

function M.apply_startup_theme()
  local name = load_theme()
  local ok = pcall(vim.cmd.colorscheme, name)
  if not ok then
    pcall(vim.cmd.colorscheme, default_theme)
  end
end

function M.setup_persist()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("PersistColorScheme", { clear = true }),
    callback = function()
      save_theme(vim.g.colors_name)
    end,
  })
end

return M
