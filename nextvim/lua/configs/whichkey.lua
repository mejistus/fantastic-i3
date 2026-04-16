local wk = require("which-key")

wk.setup({
  delay = 200,
  preset = "modern",
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = true, suggestions = 20 },
  },
  -- Ensure both <leader> and backslash mappings are discoverable.
  triggers = {
    { "<leader>", mode = { "n", "v" } },
    { "\\", mode = { "n", "v" } },
  },
})
