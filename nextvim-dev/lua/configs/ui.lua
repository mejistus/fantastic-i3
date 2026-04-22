local M = {}

function M.nvim_window()
  require("nvim-window").setup({
    chars = {
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
      "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    },
    normal_hl = "Normal",
    hint_hl = "Bold",
    border = "single",
  })
end

function M.im_select()
  require("im_select").setup({
    default_im_select = "com.apple.keylayout.ABC",
    default_command = "macism",
    set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
    set_previous_events = { "InsertEnter" },
    keep_quiet_on_no_binary = true,
    async_switch_im = true,
  })
end

function M.better_escape()
  require("better_escape").setup({
    timeout = 200,
    default_mappings = true,
    mappings = {
      i = { j = { k = "<Esc>" }, [";"] = { [";"] = "<Esc>" } },
      t = { j = { k = "<C-\\><C-n>" } },
      v = { j = { k = "<Esc>" }, [";"] = { [";"] = "<Esc>" } },
      s = { j = { k = "<Esc>" }, [";"] = { [";"] = "<Esc>" } },
    },
  })
end

function M.neoscroll()
  require("neoscroll").setup({
    mappings = { "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = true,
    stop_eof = true,
    cursor_scrolls_alone = true,
    duration_multiplier = 0.5,
    easing = "linear",
  })
end

function M.transparent()
  require("transparent").setup({
    groups = {
      "Normal", "NormalNC", "Comment", "Constant", "Special", "Identifier",
      "Statement", "PreProc", "Type", "Underlined", "Todo", "String", "Function",
      "Conditional", "Repeat", "Operator", "Structure", "NonText", "SignColumn",
      "CursorLine", "CursorLineNr", "StatusLine", "StatusLineNC", "EndOfBuffer", "Folded",
    },
    extra_groups = {
      "NormalFloat",
      "Pmenu",
      "TelescopeNormal",
      "TelescopeBorder",
      "TelescopePromptBorder",
      "TelescopeResultsBorder",
      "TelescopePreviewBorder",
      "CmpPmenu",
      "CmpBorder",
      "LspInlayHint",
    },
    exclude_groups = { "Visual", "VisualNC" },
  })
end

function M.chafa()
  require("chafa").setup({
    render = { min_padding = 5, show_label = true },
    events = { update_on_nvim_resize = true },
  })
end

function M.render_markdown()
  require("render-markdown").setup({ file_types = { "markdown", "vimwiki" } })
  vim.treesitter.language.register("markdown", "vimwiki")
end

return M
