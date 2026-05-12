return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
    },
    { "catppuccin/nvim",          name = "catppuccin", lazy = false,  priority = 900 },
    { "ellisonleao/gruvbox.nvim", lazy = false,        priority = 900 },
    { "rebelot/kanagawa.nvim",    lazy = false,        priority = 900 },
    { "rose-pine/neovim",         name = "rose-pine",  lazy = false,  priority = 900 },
    { "EdenEast/nightfox.nvim",   lazy = false,        priority = 900 },
    {
        "vhyrro/luarocks.nvim",
        priority = 1001,
        opts = {
            rocks = { "magick" },
        },
    },

    { "nvim-lua/plenary.nvim",       lazy = true },
    { "nvim-tree/nvim-web-devicons", lazy = true },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("configs.whichkey")
        end,
    },
    { "numToStr/Comment.nvim",             keys = { "gc", "gcc" },                       opts = {} },
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("configs.bufferline")
        end,
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                char = {
                    keys = {
                        ["f"] = false,
                        ["t"] = false,
                        ["F"] = false,
                        ["T"] = false,
                    },
                },
            },
        },
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
        },
    },

    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
    },

    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.conform")
        end,
    },

    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {
            ensure_installed = {
                "lua-language-server",
                "stylua",
                "html-lsp",
                "css-lsp",
                "prettier",
                "pyright",
                "clangd",
            },
        },
    },
    { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" }, opts = {} },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
        config = function()
            require("configs.lsp")
        end,
    },

    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            {
                "windwp/nvim-autopairs",
                event = "InsertEnter",
                opts = {
                    check_ts = true,
                    disable_filetype = { "TelescopePrompt" },
                },
            },
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            {
                "L3MON4D3/LuaSnip",
                dependencies = { "rafamadriz/friendly-snippets" },
                config = function()
                    require("configs.snippets")
                end,
            },
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            require("configs.cmp")
        end,
    },

    {

        "nvim-treesitter/nvim-treesitter",
        branch = vim.fn.has("nvim-0.12") == 1 and "main" or "master",
        lazy = false,
        build = ":TSUpdate",

        config = function()
            local langs = { "python", "json", "yaml", "bash", "latex", "bibtex" }
            if vim.fn.has("nvim-0.12") == 1 then
                local ts = require("nvim-treesitter")
                ts.setup({
                    install_dir = vim.fn.stdpath("data") .. "/site",
                })
                ts.install(langs):wait(300000)
                vim.treesitter.language.register("bash", { "zsh" })
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = {
                        "python",
                        "json",
                        "yaml",
                        "bash",
                        "zsh",
                        "tex",
                        "plaintex",
                        "bib",
                    },
                    callback = function(args)
                        local ft = vim.bo[args.buf].filetype
                        local map = {
                            zsh = "bash",
                            tex = "latex",
                            plaintex = "latex",
                            bib = "bibtex",

                        }
                        local lang = map[ft] or ft
                        pcall(vim.treesitter.start, args.buf, lang)
                    end,
                })
            else
                require("nvim-treesitter.configs").setup({
                    ensure_installed = langs,
                    sync_install = false,
                    auto_install = true,
                    highlight = {
                        enable = true,
                    },
                    indent = {
                        enable = true,
                    },
                })
                vim.treesitter.language.register("bash", "zsh")
            end
        end,
    },

    {
        "mfussenegger/nvim-dap",
        keys = { "<F5>", "<F6>", "<F10>", "<F11>", "<F12>" },
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            require("configs.dap")
        end,
    },
    {
        "geg2102/nvim-jupyter-client",
        event = {
            "BufReadPre *.ipynb",
            "BufNewFile *.ipynb",
        },
        cmd = {
            "JupyterAddCellBelow",
            "JupyterAddCellAbove",
            "JupyterRemoveCell",
            "JupyterMergeCellAbove",
            "JupyterMergeCellBelow",
            "JupyterConvertCellType",
            "JupyterDeleteCell",
            "JupyterMergeVisual",
        },
        keys = {
            { "<leader>ja", "<cmd>JupyterAddCellBelow<CR>",    desc = "Add Jupyter cell below" },
            { "<leader>jA", "<cmd>JupyterAddCellAbove<CR>",    desc = "Add Jupyter cell above" },

            { "<leader>jd", "<cmd>JupyterRemoveCell<CR>",      desc = "Remove current Jupyter cell" },
            { "<leader>jm", "<cmd>JupyterMergeCellAbove<CR>",  desc = "Merge with cell above" },
            { "<leader>jM", "<cmd>JupyterMergeCellBelow<CR>",  desc = "Merge with cell below" },
            { "<leader>jt", "<cmd>JupyterConvertCellType<CR>", desc = "Convert cell type (code/markdown)" },
            { "<leader>jD", "<cmd>JupyterDeleteCell<CR>",      desc = "Delete cell under cursor and store in register" },

            { "<leader>jm", "<cmd>JupyterMergeVisual<CR>",     mode = "v",                                             desc = "Merge selected cells" },
        },
        opts = {
            template = {
                cells = {
                    {
                        cell_type = "code",
                        execution_count = nil,
                        metadata = {},
                        outputs = {},
                        source = { "# Custom template cell\n" },
                    },
                },
                metadata = {
                    kernelspec = {
                        display_name = "Python 3",
                        language = "python",
                        name = "python3",
                    },
                },
                nbformat = 4,
                nbformat_minor = 5,
            },
            cell_highlight_group = "CurSearch",
            highlights = {
                cell_title = {
                    fg = "#ffffff",
                    bg = "#000000",
                },
            },
        },
        config = function(_, opts)
            require("nvim-jupyter-client").setup(opts)
        end,
    },

    {
        "stevearc/oil.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("configs.oil")
        end,
    },

    { "yorickpeterse/nvim-window",    event = "VeryLazy",    config = function() require("configs.ui").nvim_window() end },
    { "keaising/im-select.nvim",      event = "VeryLazy",    config = function() require("configs.ui").im_select() end },
    { "max397574/better-escape.nvim", event = "InsertEnter", config = function() require("configs.ui").better_escape() end },
    { "karb94/neoscroll.nvim",        event = "VeryLazy",    config = function() require("configs.ui").neoscroll() end },
    { "xiyaowong/transparent.nvim",   event = "VeryLazy",    config = function() require("configs.ui").transparent() end },
    {
        "princejoogie/chafa.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "m00qek/baleia.nvim" },
        config = function()
            require("configs.ui").chafa()
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "vimwiki" },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
        config = function()
            require("configs.ui").render_markdown()
        end,
    },
    {
        "mikesmithgh/kitty-scrollback.nvim",
        enabled = true,
        lazy = true,
        cmd = {
            "KittyScrollbackGenerateKittens",
            "KittyScrollbackCheckHealth",
            "KittyScrollbackGenerateCommandLineEditing",
        },
        event = { "User KittyScrollbackLaunch" },
        config = function()
            require("kitty-scrollback").setup()
        end,
    },

    {
        "lervag/vimtex",
        ft = { "tex", "plaintex" },
        init = function()
            require("configs.vimtex")
        end,
    },

    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        version = false,
        build = "env -u CARGO_TARGET_DIR make BUILD_FROM_SOURCE=true",
        init = function()
            require("avante_lib").load()
        end,
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
            "MeanderingProgrammer/render-markdown.nvim",
        },
        opts = {
            provider = "siliconflow",
            providers = {
                siliconflow = {
                    __inherited_from = "openai",
                    endpoint = "https://api.siliconflow.cn/v1",
                    api_key_name = "SILICONFLOW_API_TOKEN",
                    model = "Qwen/Qwen3.5-9B",
                    timeout = 30000,
                    max_tokens = 224000,
                    extra_request_body = {
                        temperature = 0.0,
                        stream = true,
                        enable_thinking = true,
                    },
                    model_names = {
                        "Qwen/Qwen3.5-4B",
                        "Qwen/Qwen3.5-9B",
                        "Qwen/Qwen3-32B",
                        "Qwen/Qwen3-Coder-480B-A35B-Instruct",
                    },
                },
                siliconflow_no_think = {
                    __inherited_from = "openai",
                    endpoint = "https://api.siliconflow.cn/v1",
                    model = "deepseek-ai/DeepSeek-V3.2",
                    api_key_name = "SILICONFLOW_API_TOKEN",
                    timeout = 30000,
                    max_tokens = 224000,
                    extra_request_body = {
                        temperature = 0.0,
                        stream = true,
                    },
                    model_names = {
                        "deepseek-ai/DeepSeek-V3.2",
                        "deepseek-ai/DeepSeek-V3",
                    },
                },
            },
            behaviour = {
                auto_suggestions = false,
                auto_set_keymaps = true,
                auto_set_highlight_group = true,
                support_paste_from_clipboard = true,
            },
            hints = { enabled = true },
            windows = {
                ask = { start_insert = false },
            },
            mappings = {
                toggle = {
                    selection = "<leader>aC",
                },
            },
        },
        config = function(_, opts)
            require("avante").setup(opts)
            -- Fix: avante maps toggle.selection to M.toggle.hint() which doesn't exist,
            -- remap to the correct M.toggle.selection()
            vim.keymap.set("n", "<leader>aC", function()
                require("avante").toggle.selection()
            end, { desc = "avante: toggle selection", noremap = true, silent = true })
            vim.keymap.set("n", "\\<Tab>", function()
                require("avante").toggle()
            end, { desc = "avante: toggle", noremap = true, silent = true })
        end,
    },
}
