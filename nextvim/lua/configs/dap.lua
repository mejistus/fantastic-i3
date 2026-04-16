local dap = require("dap")
local dapui = require("dapui")

dapui.setup()
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

require("nvim-dap-virtual-text").setup({
  enabled = true,
  enabled_commands = false,
  highlight_changed_variables = true,
  highlight_new_as_changed = false,
  show_stop_reason = true,
  commented = false,
  only_first_definition = true,
  all_references = true,
  clear_on_continue = false,
  display_callback = function(variable, _, _, _, options)
    if options.virt_text_pos == "inline" then
      return " = " .. variable.value:gsub("%s+", " ")
    end
    return variable.name .. " = " .. variable.value:gsub("%s+", " ")
  end,
  virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
  all_frames = false,
  virt_lines = true,
  virt_text_win_col = nil,
})

dap.adapters.python = {
  type = "executable",
  command = "python",
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    pythonPath = function()
      return os.getenv("HOME") .. "/.virtualenvs/neovim/bin/python"
    end,
  },
}

local lldb = os.getenv("HOME") .. "/.local/share/nvim/mason/bin/codelldb"
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = lldb,
    args = { "--port", "${port}" },
  },
}

dap.configurations.cpp = {
  {
    name = "runit",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    args = { "--log_level=all" },
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    terminal = "integrated",
  },
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
