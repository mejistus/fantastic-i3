local config = {
  ensure_installed = {
    "vim",
    "lua",
    "vimdoc",
    "html",
    "css",
    "python",
    "cpp",
    "c",
    "markdown",
  },
  highlight = { enable = true },
  indent = { enable = true },
  textobjects = {
    move = {
      enable = true,
      set_jumps = false,
      goto_next_start = { ["]b"] = { query = "@code_cell.inner", desc = "next code block" } },
      goto_previous_start = { ["[b"] = { query = "@code_cell.inner", desc = "previous code block" } },
    },
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["ib"] = { query = "@code_cell.inner", desc = "in block" },
        ["ab"] = { query = "@code_cell.outer", desc = "around block" },
      },
    },
    swap = {
      enable = true,
      swap_next = { ["<leader>sbl"] = "@code_cell.outer" },
      swap_previous = { ["<leader>sbh"] = "@code_cell.outer" },
    },
  },
}

local ok_new, ts = pcall(require, "nvim-treesitter")
if ok_new and ts.setup then
  ts.setup(config)
else
  local ok_old, legacy = pcall(require, "nvim-treesitter.configs")
  if ok_old then
    legacy.setup(config)
  end
end
