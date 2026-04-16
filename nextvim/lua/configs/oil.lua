local oil = require("oil")

require("oil.actions").preview = {
  desc = "Preview images with chafa; fallback for others",
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

    local util = require("oil.util")
    local winid = util.get_preview_win()
    if winid and vim.w[winid].oil_entry_id == entry.id then
      vim.api.nvim_win_close(winid, true)
      return
    end

    local path = oil.get_current_dir() .. "/" .. entry.name
    local ext = path:match("^.+(%..+)$")
    local image_exts = { [".png"] = true, [".jpg"] = true, [".jpeg"] = true, [".webp"] = true, [".bmp"] = true, [".gif"] = true }

    if entry.type == "file" and ext and image_exts[ext:lower()] then
      local split = opts.split or "botright"
      local cmd = (opts.vertical and split .. " vsplit") or (opts.horizontal and split .. " split") or (split .. " vsplit")
      vim.cmd(cmd)
      local preview_win = vim.api.nvim_get_current_win()
      vim.cmd("wincmd p")

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(preview_win, buf)
      vim.fn.termopen({ "chafa", path })
      vim.bo[buf].buftype = "terminal"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.api.nvim_buf_set_name(buf, "preview://" .. entry.name)
      vim.w[preview_win].oil_preview = true
      vim.w[preview_win].oil_entry_id = entry.id
    else
      oil.open_preview(opts)
    end
  end,
}

oil.setup({
  default_file_explorer = true,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  view_options = {
    show_hidden = false,
    case_insensitive = true,
    natural_order = "fast",
  },
  keymaps = {
    ["<CR>"] = "actions.select",
    ["l"] = "actions.select",
    ["h"] = { "actions.parent", mode = "n" },
    ["<C-p>"] = "actions.preview",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["<C-l>"] = "actions.refresh",
  },
  float = { border = "rounded" },
  preview_win = { update_on_cursor_moved = true, preview_method = "fast_scratch" },
})
