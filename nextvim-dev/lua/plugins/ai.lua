return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "j-hui/fidget.nvim",
    },
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionCmd",
      "CodeCompanionActions",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "AI Chat", mode = { "n", "v" } },
      { "<leader>ai", "<cmd>CodeCompanionInline<cr>", desc = "AI Inline Edit", mode = { "n", "v" } },
      { "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI Toggle Chat" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "AI New Chat", mode = { "n", "v" } },
      { "<C-a>", "<cmd>CodeCompanion<cr>", desc = "AI Prompt", mode = { "n", "v" } },
      { "ga", "<cmd>CodeCompanionAdd<cr>", desc = "AI Add to Chat", mode = { "v" } },
    },
    config = function()
      require("configs.codecompanion")
    end,
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "j-hui/fidget.nvim",
    },
    keys = {
      { "<leader>av", "<cmd>AvanteAsk<cr>", desc = "AI Avante Ask", mode = { "n", "v" } },
      { "<leader>ar", "<cmd>AvanteChat<cr>", desc = "AI Avante Chat" },
      { "<leader>af", "<cmd>AvanteFocus<cr>", desc = "AI Avante Focus" },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "AI Avante Edit", mode = { "n", "v" } },
      { "<leader>as", "<cmd>AvanteSwitch<cr>", desc = "AI Switch Provider" },
    },
    config = function()
      require("configs.avante")
    end,
  },
}
