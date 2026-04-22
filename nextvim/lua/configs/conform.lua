require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    python = { "autopep8" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    cpp = { "clang-format" },
    c = { "clang-format" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})
