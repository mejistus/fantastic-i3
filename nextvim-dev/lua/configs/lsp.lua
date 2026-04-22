local capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "F", vim.lsp.buf.hover, opts)
end

local servers = {
  "html",
  "cssls",
  "cmake",
  "ts_ls",
  "texlab",
  "bashls",
  "jsonls",
  "arduino_language_server",
}

local default_opts = {
  on_attach = on_attach,
  capabilities = capabilities,
}

local custom = {
  clangd = {
    cmd = { "clangd", "--background-index", "--clang-tidy" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  },
  pyright = {
    cmd_env = { NODE_OPTIONS = "--max-old-space-size=6000" },
    settings = {
      python = {
        analysis = {
          diagnosticSeverityOverrides = {
            reportAttributeAccessIssue = "warning",
            reportIncompatibleMethodUsage = "information",
            reportIncompatibleVariableUsage = "information",
            reportOptionalSubscript = "none",
            reportOptionalUnnecessary = "information",
            reportOptionalUnspecified = "warning",
            reportUnnecessaryTypeIgnoreComment = "none",
            reportAssignmentType = "information",
            reportArgumentType = "warning",
            reportCallIssue = "warning",
            reportOperatorIssue = "warning",
            reportPrivateImportUsage = "information",
          },
        },
      },
    },
  },
}

local all_servers = vim.list_extend(vim.deepcopy(servers), { "clangd", "pyright" })

if vim.lsp.config and vim.lsp.enable then
  for _, server in ipairs(all_servers) do
    local opts = vim.tbl_deep_extend("force", vim.deepcopy(default_opts), custom[server] or {})
    vim.lsp.config(server, opts)
    vim.lsp.enable(server)
  end
else
  local lspconfig = require("lspconfig")
  for _, server in ipairs(all_servers) do
    local opts = vim.tbl_deep_extend("force", vim.deepcopy(default_opts), custom[server] or {})
    lspconfig[server].setup(opts)
  end
end
