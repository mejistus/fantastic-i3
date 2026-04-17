local oil = require("oil")
local util = require("oil.util")
local actions = require("oil.actions")

local image_exts = { [".png"] = true, [".jpg"] = true, [".jpeg"] = true, [".webp"] = true, [".bmp"] = true, [".gif"] = true }
local preview_mode = false
local original_preview = actions.preview
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
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(preview_win, buf)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen({ "chafa", preview_path })
  end)
  vim.bo[buf].buftype = "terminal"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_name(buf, "preview://" .. entry.name)
  vim.w[preview_win].oil_preview = true
  vim.w[preview_win].oil_entry_id = entry.id
end

local function update_preview(opts)
  local entry = oil.get_cursor_entry()
  if not entry then
    return
  end

  local preview_win = util.get_preview_win()
  if not (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
    return
  end

  if is_image_entry(entry) then
    if vim.w[preview_win].oil_entry_id ~= entry.id then
      render_image_preview(entry, opts)
    end
  else
    original_preview.callback(opts or {})
  end
end

actions.preview = {
  desc = "Use chafa to preview images; fallback to default preview for others",
  parameters = {
    vertical = { type = "boolean", desc = "Open in vertical split" },
    horizontal = { type = "boolean", desc = "Open in horizontal split" },
    split = { type = '"aboveleft"|"belowright"|"topleft"|"botright"', desc = "Split modifier" },
  },
  callback = function(opts)
    opts = opts or {}
    local entry = oil.get_cursor_entry()
    if not entry then
      vim.notify("No entry under cursor", vim.log.levels.ERROR)
      return
    end

    local preview_win = util.get_preview_win()
    if preview_win and vim.api.nvim_win_is_valid(preview_win) and vim.w[preview_win].oil_entry_id == entry.id then
      vim.api.nvim_win_close(preview_win, true)
      preview_mode = false
      return
    end

    preview_mode = true
    if is_image_entry(entry) then
      render_image_preview(entry, opts)
    else
      original_preview.callback(opts)
    end
  end,
}

actions.select = {
  desc = "Select entry; preview images with chafa",
  parameters = {
    vertical = { type = "boolean", desc = "Open in vertical split" },
    horizontal = { type = "boolean", desc = "Open in horizontal split" },
    tab = { type = "boolean", desc = "Open in new tab" },
    close = { type = "boolean", desc = "Close oil when done" },
  },
  callback = function(opts)
    local entry = oil.get_cursor_entry()
    if entry and is_image_entry(entry) then
      preview_mode = true
      render_image_preview(entry, opts or {})
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

vim.api.nvim_create_autocmd("CursorMoved", {
  group = vim.api.nvim_create_augroup("OilImagePreviewFollow", { clear = true }),
  pattern = "*",
  callback = function()
    if not preview_mode or vim.bo.filetype ~= "oil" then
      return
    end
    local preview_win = util.get_preview_win()
    if not (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
      preview_mode = false
      return
    end
    update_preview({})
  end,
})
