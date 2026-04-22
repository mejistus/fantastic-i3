local M = {}

M = {
  strategies = {
    chat = {
      adapter = "siliconflow",
    },
    inline = {
      adapter = "siliconflow",
    },
    cmd = {
      adapter = "siliconflow",
    },
  },
  adapters = {
    siliconflow = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        name = "siliconflow",
        formatted_name = "SiliconFlow",
        env = {
          url = "https://api.siliconflow.cn",
          api_key = "SILICONFLOW_API_KEY",
          chat_url = "/v1/chat/completions",
        },
        headers = {
          ["Content-Type"] = "application/json",
          Authorization = "Bearer ${api_key}",
        },
        parameters = {
          model = "Qwen/Qwen2.5-Coder-32B-Instruct",
          temperature = 0.3,
          max_tokens = 4096,
        },
        schema = {
          model = {
            order = 1,
            type = "enum",
            desc = "ID of the model to use.",
            choices = {
              "Qwen/Qwen2.5-Coder-32B-Instruct",
              "deepseek-ai/DeepSeek-V3",
              "Pro/deepseek-ai/DeepSeek-V3",
              "deepseek-ai/DeepSeek-R1",
              "Pro/deepseek-ai/DeepSeek-R1",
              "Pro/zai-org/GLM-5.1",
              "Pro/moonshotai/Kimi-K2.5",
            },
          },
          temperature = {
            order = 2,
            type = "number",
            desc = "What sampling temperature to use, between 0 and 2.",
          },
          max_tokens = {
            order = 3,
            type = "integer",
            desc = "The maximum number of tokens to generate.",
          },
        },
      })
    end,
  },
  prompt_library = {
    ["Explain Code"] = {
      strategy = "chat",
      description = "Explain the selected code",
      opts = {
        modes = { "v" },
        short_name = "explain",
        auto_submit = true,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert software engineer. Explain code clearly and concisely in the same language as the user's question. Use markdown formatting.",
        },
        {
          role = "user",
          content = "Please explain this code:\n\n{{selection}}",
        },
      },
    },
    ["Review Code"] = {
      strategy = "chat",
      description = "Review the selected code for bugs and improvements",
      opts = {
        modes = { "v" },
        short_name = "review",
        auto_submit = true,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert code reviewer. Identify bugs, security issues, performance problems, and suggest improvements. Be specific and provide corrected code snippets.",
        },
        {
          role = "user",
          content = "Review this code for issues and improvements:\n\n{{selection}}",
        },
      },
    },
    ["Generate Tests"] = {
      strategy = "chat",
      description = "Generate tests for the selected code",
      opts = {
        modes = { "v" },
        short_name = "test",
        auto_submit = true,
        stop_context_insertion = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert test engineer. Write comprehensive unit tests. Use the testing framework appropriate for the language. Cover edge cases and error conditions.",
        },
        {
          role = "user",
          content = "Generate comprehensive tests for this code:\n\n{{selection}}",
        },
      },
    },
    ["Refactor"] = {
      strategy = "inline",
      description = "Refactor the selected code",
      opts = {
        modes = { "v" },
        short_name = "refactor",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert software engineer who refactors code to be clean, maintainable, and idiomatic. Preserve existing behavior.",
        },
        {
          role = "user",
          content = "Refactor this code to be cleaner and more idiomatic, preserving its behavior:\n\n{{selection}}",
        },
      },
    },
    ["Fix Bug"] = {
      strategy = "inline",
      description = "Fix bugs in the selected code",
      opts = {
        modes = { "v" },
        short_name = "fix",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert debugger. Fix bugs while minimizing changes. Preserve the original code's intent and style.",
        },
        {
          role = "user",
          content = "Fix the bugs in this code:\n\n{{selection}}",
        },
      },
    },
    ["Document"] = {
      strategy = "inline",
      description = "Add documentation to the selected code",
      opts = {
        modes = { "v" },
        short_name = "doc",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = "You are an expert technical writer. Add clear, concise documentation following the language's conventions. Do not change the code itself.",
        },
        {
          role = "user",
          content = "Add documentation/comments to this code:\n\n{{selection}}",
        },
      },
    },
  },
  display = {
    chat = {
      window = {
        layout = "vertical",
        width = 0.35,
      },
      show_settings = true,
    },
    diff = {
      enabled = true,
      close_chat_at = 240,
    },
  },
  opts = {
    log_level = "INFO",
    language = "Chinese",
  },
}

local ok, codecompanion = pcall(require, "codecompanion")
if ok then
  codecompanion.setup(M)
end

return M
