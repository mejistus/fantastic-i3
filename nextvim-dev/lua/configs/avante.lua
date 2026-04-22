local M = {}

M = {
  provider = "siliconflow",
  auto_suggestions_provider = "siliconflow",
  behaviour = {
    auto_suggestions = false,
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false,
    support_paste_from_clipboard = true,
  },
  providers = {
    siliconflow = {
      __inherited_from = "openai",
      endpoint = "https://api.siliconflow.cn/v1",
      model = "Qwen/Qwen2.5-Coder-32B-Instruct",
      api_key_name = "SILICONFLOW_API_KEY",
      timeout = 30000,
      context_window = 32768,
      extra_request_body = {
        temperature = 0.3,
        max_tokens = 4096,
      },
    },
  },
  hints = { enabled = true },
  windows = {
    wrap = true,
    width = 40,
    sidebar_header = {
      enabled = true,
      align = "center",
      rounded = true,
    },
    input = {
      prefix = "> ",
      height = 8,
    },
  },
  highlights = {
    diff = {
      current = "DiffText",
      incoming = "DiffAdd",
    },
  },
  diff = {
    autojump = true,
  },
  mappings = {
    ask = "<leader>av",
    edit = "<leader>ae",
    refresh = "<leader>ar",
    diff = {
      ours = "co",
      theirs = "ct",
      both = "cb",
      next = "]x",
      prev = "[x",
    },
    jump = {
      next = "]]",
      prev = "[[",
    },
  },
}

local ok, avante = pcall(require, "avante")
if ok then
  avante.setup(M)
end

return M
