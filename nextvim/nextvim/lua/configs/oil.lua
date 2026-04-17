local oil = require("oil")
local util = require("oil.util")
local actions = require("oil.actions")

local image_exts = { [".png"] = true, [".jpg"] = true, [".jpeg"] = true, [".webp"] = true, [".bmp"] = true, [".gif"] = true }
local original_select = actions.select

local function get_entry_path(entry)
  local path = oil.get_current_dir() .. "/" .. entry.name
  return vim.loop.fs_realpath(path) or path
end

local function is_image_entry(entry)
  if not entry or (entry.type ~= "file" and entry.type ~= "link") then
    return false
  end
  local preview_path = get_entry_path(entry)
  local ext = preview_path:match("^.+(%..+)$")
  return ext and image_exts[ext:lower()] or false
end

local function ensure_preview_window(opts)
  local preview_win = util.get_preview_win()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    return preview_win
  end

  opts = opts or {}
  local split = opts.split or "botright"
  local cmd = (opts.vertical and split .. " vsplit") or (opts.horizontal and split .. " split") or (split .. " vsplit")
  vim.cmd(cmd)
  preview_win = vim.api.nvim_get_current_win()
  vim.wo[preview_win].previewwindow = true
  vim.cmd("wincmd p")
  return preview_win
end

local function render_image_preview(entry, opts)
  if vim.fn.executable("chafa") ~= 1 then
    vim.notify("chafa not found", vim.log.levels.WARN)
    return
  end

  local preview_path = get_entry_path(entry)
  local preview_win = ensure_preview_window(opts)
  if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then return end

  -- Create a new terminal buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Safely set buffer to window
  if vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_set_buf(preview_win, buf)
  else
    return
  end
  
  -- Run chafa in the terminal buffer using nvim_buf_call
  vim.api.nvim_buf_call(buf, function()
    pcall(vim.fn.termopen, { "chafa", preview_path })
  end)

  -- Set buffer options safely
  if vim.api.nvim_buf_is_valid(buf) then
    vim.bo[buf].buftype = "terminal"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    pcall(vim.api.nvim_buf_set_name, buf, "preview://" .. entry.name)
  end
  
  -- Mark the window as our preview window safely
  if vim.api.nvim_win_is_valid(preview_win) then
    vim.w[preview_win].oil_preview = true
    vim.w[preview_win].oil_entry_id = entry.id
    vim.w[preview_win].oil_source_win = vim.api.nvim_get_current_win()
  end
end

local original_open_preview = oil.open_preview
oil.open_preview = function(opts, callback)
  opts = opts or {}
  opts.vertical = true
  opts.split = "botright"

  local entry = oil.get_cursor_entry()
  if entry and is_image_entry(entry) then
    render_image_preview(entry, opts)
    if callback then callback() end
  else
    original_open_preview(opts, callback)
  end

  local preview_win = util.get_preview_win()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    local total_width = vim.o.columns
    local preview_width = math.floor(total_width * 2 / 3)
    vim.api.nvim_win_set_width(preview_win, preview_width)
  end
end

local function open_image(entry, opts)
  if vim.fn.executable("chafa") ~= 1 then
    vim.notify("chafa not found", vim.log.levels.WARN)
    return
  end

  local preview_path = get_entry_path(entry)
  
  if opts.vertical then
    vim.cmd("vsplit")
  elseif opts.horizontal then
    vim.cmd("split")
  elseif opts.tab then
    vim.cmd("tabnew")
  else
    vim.cmd("tabnew")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen({ "chafa", preview_path })
  end)
  vim.bo[buf].buftype = "terminal"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_name(buf, "image://" .. entry.name)
end

actions.select = {
  desc = "Select entry; preview images with chafa",
  parameters = {
    vertical = { type = "boolean", desc = "Open in vertical split" },
    horizontal = { type = "boolean", desc = "Open in horizontal split" },
    tab = { type = "boolean", desc = "Open in new tab" },
    close = { type = "boolean", desc = "Close oil when done" },
  },
  callback = function(opts)
    opts = opts or {}
    local entry = oil.get_cursor_entry()
    if entry and is_image_entry(entry) then
      open_image(entry, opts)
      return
    end
    original_select.callback(opts)
  end,
}

oil.setup({
  default_file_explorer = true,
  restore_win_options = true,
  columns = {
    "icon",
    "size",
  },
  buf_options = {
    buflisted = false,
    bufhidden = "hide",
  },
  win_options = {
    signcolumn = "no",
    number = false,
    relativenumber = false,
    wrap = false,
    cursorcolumn = false,
    foldcolumn = "1",
    spell = false,
    list = true,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = true,
  cleanup_delay_ms = 2000,
  view_options = {
    show_hidden = false,
    case_insensitive = true,
    natural_order = "fast",
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["l"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["h"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["<C-p>"] = "actions.preview",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
    ["<C-l>"] = "actions.refresh",
  },
  float = { border = "rounded" },
  preview_win = { update_on_cursor_moved = true, preview_method = "fast_scratch" },
})
