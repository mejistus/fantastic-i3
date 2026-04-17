local wk = require("which-key")

wk.setup({
  delay = 200,
  preset = "modern",
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = true, suggestions = 20 },
  },
  -- Keep discovery on leader and window-management backslash maps.
  triggers = {
    { "<leader>", mode = { "n", "v" } },
    { "\\", mode = { "n" } },
  },
})
