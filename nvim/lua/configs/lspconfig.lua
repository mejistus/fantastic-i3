-- EXAMPLE
-- local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    -- 取消默认的 K 映射（可选）
    vim.keymap.set("n", "K", "<C-u>", opts)

    -- 设置 F 为 hover 文档
    vim.keymap.set("n", "F", vim.lsp.buf.hover, opts)
end
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities
local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "pyright",
    "clangd", "cmake", "cssls", "html", "ts_ls",
    "texlab", "bashls", "jsonls" ,"arduino_language_server"}

-- lsps with default config
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
        on_attach = on_attach,
        on_init = on_init,
        capabilities = capabilities,
    }
end


require("lspconfig").pyright.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        python = { -- ← 这一层不能少
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                diagnosticSeverityOverrides = {
                    reportAttributeAccessIssue         = "warning",
                    reportIncompatibleMethodUsage      = "information",
                    reportIncompatibleVariableUsage    = "information",
                    reportOptionalSubscript            = "none",
                    reportOptionalUnnecessary          = "information",
                    reportOptionalUnspecified          = "warning",
                    reportUnnecessaryTypeIgnoreComment = "none",
                    reportAssignmentType = "information",
                    reportArgumentType = 'warning',
                    reportCallIssue = "warning",
                    reportOperatorIssue = "warning",
                    reportPrivateImportUsage = "information"
                },
            },
        },
    },
    cmd_env = { NODE_OPTIONS = "--max-old-space-size=6000" },
}
