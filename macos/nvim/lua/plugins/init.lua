local lazy = require "lazy"

return {
    {
        "stevearc/conform.nvim",
        -- event = 'BufWritePre', -- uncomment for format on save
        config = function() require "configs.conform" end
    }, -- These are some examples, uncomment them if you want to see them work!
    {
        "neovim/nvim-lspconfig",
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require "configs.lspconfig"
        end
    },
    {
        "williamboman/mason.nvim",
        opts = { ensure_installed = { "lua-language-server", "stylua", "html-lsp", "css-lsp", "prettier" } }
    },
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = { "vim", "lua", "vimdoc", "html", "css" }
        }
    },
    {
        'stevearc/oil.nvim',
        opts = {},
        dependencies = { { "echasnovski/mini.icons", opts = {} } },
        -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
        lazy = false,
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio", 'theHamsta/nvim-dap-virtual-text' }
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                char = {
                    keys = {
                        ["f"] = false, -- 禁用 f
                        ["t"] = false, -- 禁用 t
                        ["F"] = false, -- 可选：禁用大写 F
                        ["T"] = false, -- 可选：禁用大写 T
                    },
                },
            },
        },
        -- stylua: ignore
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        },
    },
    {
        "yorickpeterse/nvim-window",
    },

    {
        "Exafunction/codeium.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
        },
        config = function()
        end
    },
    {
        "lervag/vimtex",
        lazy = false, -- we don't want to lazy load VimTeX
        -- tag = "v2.15", -- uncomment to pin to a specific release
        init = function()
            -- VimTeX configuration goes here, e.g.
        end
    },
    {
        "keaising/im-select.nvim",
        config = function()

        end,
    }
    ,
    {
        'mikesmithgh/kitty-scrollback.nvim',
        enabled = true,
        lazy = true,
        cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth', 'KittyScrollbackGenerateCommandLineEditing' },
        event = { 'User KittyScrollbackLaunch' },
        config = function()
            require('kitty-scrollback').setup()
        end,
    },
    -- lua with lazy.nvim
    {
        "max397574/better-escape.nvim",
        config = function()
            require("better_escape").setup()
        end,
    },
    {
        'nvim-treesitter/playground',
        cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require("nvim-treesitter.configs").setup {
                playground = {
                    enable = true,
                    updatetime = 25,
                    persist_queries = false,
                }
            }
        end
    }
    ,
    {
        "karb94/neoscroll.nvim",
        opts = {},
    },
    {
        "xiyaowong/transparent.nvim",
        config = function()
        end
    },
    {
        "princejoogie/chafa.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "m00qek/baleia.nvim"
        }
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
		cmd = { 'RenderMarkdown' },
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    }
}
