local wk = require("which-key")

wk.setup({
  delay = 200,
  preset = "modern",
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = true, suggestions = 20 },
  },
  triggers = {
    { "<leader>", mode = { "n", "v" } },
    { "\\", mode = { "n" } },
  },
})

wk.add({
  { "<leader>a", group = "AI", icon = "" },
  { "<leader>aa", desc = "AI Actions" },
  { "<leader>ac", desc = "AI Chat" },
  { "<leader>ai", desc = "AI Inline Edit" },
  { "<leader>at", desc = "AI Toggle Chat" },
  { "<leader>an", desc = "AI New Chat" },
  { "<leader>av", desc = "AI Avante Ask" },
  { "<leader>ar", desc = "AI Avante Chat" },
  { "<leader>af", desc = "AI Avante Focus" },
  { "<leader>ae", desc = "AI Avante Edit" },
  { "<leader>as", desc = "AI Switch Provider" },
})
