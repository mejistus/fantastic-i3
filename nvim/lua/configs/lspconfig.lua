-- EXAMPLE
-- local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set("n", "K", "<C-u>", opts)

    vim.keymap.set("n", "F", vim.lsp.buf.hover, opts)
end
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities
local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "pyright",
    "clangd", "cmake", "cssls", "html", "ts_ls",
    "texlab", "bashls", "jsonls" }

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
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                diagnosticSeverityOverrides = {
                    reportAttributeAccessIssue         = "none",
                    reportIncompatibleMethodUsage      = "information",
                    reportIncompatibleVariableUsage    = "information",
                    reportOptionalSubscript            = "none",
                    reportOptionalUnnecessary          = "information",
                    reportOptionalUnspecified          = "warning",
                    reportUnnecessaryTypeIgnoreComment = "none",
                    reportAssignmentType               = "information",
                    reportOptionalMemberAccess         = "none",
                    reportUnboundVariable              = "warning",
                    reportArgumentType                 = "warning",
                    reportPossiblyUnboundVariable      = "information",
                    reportPrivateImportUsage           = "information"
                },
            },
        },
    },
    cmd_env = { NODE_OPTIONS = "--max-old-space-size=4096" },
}
