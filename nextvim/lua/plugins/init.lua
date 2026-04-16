return {
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd.colorscheme("tokyonight") end },
  {
    "vhyrro/luarocks.nvim",
    priority = 1001,
    opts = {
      rocks = { "magick" },
    },
  },

  { "nvim-lua/plenary.nvim", lazy = true },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("configs.whichkey")
    end,
  },
  { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
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
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
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
      "Exafunction/codeium.nvim",
    },
    config = function()
      require("configs.cmp")
    end,
  },
  { "Exafunction/codeium.nvim", opts = {} },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    config = function()
      require("configs.treesitter")
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
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("configs.oil")
    end,
  },

  { "yorickpeterse/nvim-window", event = "VeryLazy", config = function() require("configs.ui").nvim_window() end },
  { "keaising/im-select.nvim", event = "VeryLazy", config = function() require("configs.ui").im_select() end },
  { "max397574/better-escape.nvim", event = "InsertEnter", config = function() require("configs.ui").better_escape() end },
  { "karb94/neoscroll.nvim", event = "VeryLazy", config = function() require("configs.ui").neoscroll() end },
  { "xiyaowong/transparent.nvim", event = "VeryLazy", config = function() require("configs.ui").transparent() end },
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
}
