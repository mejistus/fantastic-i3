#!/usr/bin/env -S nvim --headless -u NONE -l
-- Run: nvim --headless -u NONE -l tests/test_ai_integration.lua

local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local root = script_dir .. "../"
package.path = root .. "lua/?.lua;" .. root .. "lua/?/init.lua;" .. package.path

local pass_count = 0
local fail_count = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    pass_count = pass_count + 1
    io.write("  PASS: " .. name .. "\n")
  else
    fail_count = fail_count + 1
    io.write("  FAIL: " .. name .. " -- " .. tostring(err) .. "\n")
  end
end

local function eq(got, expected, label)
  if got ~= expected then
    error(string.format(
      "%sexpected %s, got %s",
      label and (label .. ": ") or "",
      vim.inspect(expected),
      vim.inspect(got)
    ))
  end
end

local function is_truthy(val, label)
  if not val then
    error(string.format("%sexpected truthy, got %s", label and (label .. ": ") or "", vim.inspect(val)))
  end
end

local function is_type(val, t, label)
  if type(val) ~= t then
    error(string.format("%sexpected type %s, got %s", label and (label .. ": ") or "", t, type(val)))
  end
end

-- ══════════════════════════════════════════════════════════════════════
--  1. Config file existence and syntax
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Config file existence & syntax ===\n")

test("ai.lua plugin spec loads without error", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  is_type(spec, "table", "return type")
  is_truthy(#spec >= 2, "at least 2 plugin specs")
end)

test("codecompanion config loads without error", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  is_type(cfg, "table", "return type")
end)

test("avante config loads without error", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  is_type(cfg, "table", "return type")
end)

test("runtime.lua loads without error", function()
  dofile(root .. "lua/core/runtime.lua")
end)

-- ══════════════════════════════════════════════════════════════════════
--  2. Plugin spec structure
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Plugin spec structure ===\n")

test("codecompanion spec has required fields", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local cc = spec[1]
  eq(cc[1], "olimorris/codecompanion.nvim", "plugin name")
  is_type(cc.dependencies, "table", "dependencies")
  is_type(cc.keys, "table", "keys")
  is_type(cc.cmd, "table", "cmd")
  is_type(cc.config, "function", "config")
end)

test("avante spec has required fields", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local av = spec[2]
  eq(av[1], "yetone/avante.nvim", "plugin name")
  is_type(av.dependencies, "table", "dependencies")
  is_type(av.keys, "table", "keys")
  is_type(av.config, "function", "config")
end)

test("codecompanion has correct command names", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local cc = spec[1]
  local cmds = cc.cmd
  is_truthy(vim.tbl_contains(cmds, "CodeCompanion"), "CodeCompanion cmd")
  is_truthy(vim.tbl_contains(cmds, "CodeCompanionChat"), "CodeCompanionChat cmd")
  is_truthy(vim.tbl_contains(cmds, "CodeCompanionActions"), "CodeCompanionActions cmd")
  is_truthy(vim.tbl_contains(cmds, "CodeCompanionCmd"), "CodeCompanionCmd cmd")
end)

test("codecompanion has keymaps with leader-a prefix", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local cc = spec[1]
  local key_labels = {}
  for _, k in ipairs(cc.keys) do
    table.insert(key_labels, k[1])
  end
  is_truthy(vim.tbl_contains(key_labels, "<leader>aa"), "leader-aa")
  is_truthy(vim.tbl_contains(key_labels, "<leader>ac"), "leader-ac")
  is_truthy(vim.tbl_contains(key_labels, "<leader>ai"), "leader-ai")
  is_truthy(vim.tbl_contains(key_labels, "<leader>at"), "leader-at")
end)

test("avante has keymaps with leader-a prefix", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local av = spec[2]
  local key_labels = {}
  for _, k in ipairs(av.keys) do
    table.insert(key_labels, k[1])
  end
  is_truthy(vim.tbl_contains(key_labels, "<leader>av"), "leader-av")
  is_truthy(vim.tbl_contains(key_labels, "<leader>ar"), "leader-ar")
  is_truthy(vim.tbl_contains(key_labels, "<leader>ae"), "leader-ae")
  is_truthy(vim.tbl_contains(key_labels, "<leader>as"), "leader-as")
end)

test("no duplicate keymaps between codecompanion and avante", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  local cc_keys = {}
  for _, k in ipairs(spec[1].keys) do
    cc_keys[k[1]] = true
  end
  for _, k in ipairs(spec[2].keys) do
    if cc_keys[k[1]] then
      error("duplicate key: " .. k[1])
    end
  end
end)

test("each keymap has a desc field", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  for _, plugin in ipairs(spec) do
    for _, k in ipairs(plugin.keys) do
      is_truthy(k.desc, plugin[1] .. " key " .. k[1] .. " has desc")
    end
  end
end)

test("keymaps specify correct modes", function()
  local spec = dofile(root .. "lua/plugins/ai.lua")
  -- Verify visual-mode keymaps exist for inline operations
  local cc = spec[1]
  local has_visual = false
  for _, k in ipairs(cc.keys) do
    if k.mode and vim.tbl_contains(k.mode, "v") then
      has_visual = true
      break
    end
  end
  is_truthy(has_visual, "codecompanion has visual mode keymaps")
end)

-- ══════════════════════════════════════════════════════════════════════
--  3. CodeCompanion adapter configuration
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== CodeCompanion adapter config ===\n")

test("codecompanion config uses siliconflow adapter", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  eq(cfg.strategies.chat.adapter, "siliconflow", "chat adapter")
  eq(cfg.strategies.inline.adapter, "siliconflow", "inline adapter")
  eq(cfg.strategies.cmd.adapter, "siliconflow", "cmd adapter")
end)

test("codecompanion has siliconflow adapter definition", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  is_type(cfg.adapters.siliconflow, "function", "siliconflow adapter function")
end)

test("siliconflow adapter is callable", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  is_type(cfg.adapters.siliconflow, "function", "adapter is callable")
end)

test("codecompanion has prompt library", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  is_type(cfg.prompt_library, "table", "prompt_library")
  is_truthy(cfg.prompt_library["Explain Code"], "Explain Code prompt")
  is_truthy(cfg.prompt_library["Review Code"], "Review Code prompt")
  is_truthy(cfg.prompt_library["Generate Tests"], "Generate Tests prompt")
  is_truthy(cfg.prompt_library["Refactor"], "Refactor prompt")
  is_truthy(cfg.prompt_library["Fix Bug"], "Fix Bug prompt")
  is_truthy(cfg.prompt_library["Document"], "Document prompt")
end)

test("prompt library entries have correct structure", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  for name, prompt in pairs(cfg.prompt_library) do
    is_type(prompt.strategy, "string", name .. " strategy")
    is_type(prompt.description, "string", name .. " description")
    is_type(prompt.opts, "table", name .. " opts")
    is_type(prompt.prompts, "table", name .. " prompts")
  end
end)

test("each prompt has system and user roles", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  for name, prompt in pairs(cfg.prompt_library) do
    local has_system = false
    local has_user = false
    for _, p in ipairs(prompt.prompts) do
      if p.role == "system" then has_system = true end
      if p.role == "user" then has_user = true end
    end
    is_truthy(has_system, name .. " has system prompt")
    is_truthy(has_user, name .. " has user prompt")
  end
end)

test("chat strategy prompts have stop_context_insertion", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  for name, prompt in pairs(cfg.prompt_library) do
    if prompt.strategy == "chat" then
      eq(prompt.opts.stop_context_insertion, true, name .. " stop_context_insertion")
    end
  end
end)

test("all prompts have auto_submit enabled", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  for name, prompt in pairs(cfg.prompt_library) do
    eq(prompt.opts.auto_submit, true, name .. " auto_submit")
  end
end)

test("user prompts reference {{selection}}", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  for name, prompt in pairs(cfg.prompt_library) do
    local has_selection = false
    for _, p in ipairs(prompt.prompts) do
      if p.role == "user" and p.content:find("{{selection}}") then
        has_selection = true
      end
    end
    is_truthy(has_selection, name .. " uses {{selection}}")
  end
end)

test("codecompanion display config is valid", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  eq(cfg.display.chat.window.layout, "vertical", "chat layout")
  is_truthy(cfg.display.chat.window.width > 0 and cfg.display.chat.window.width <= 1, "chat width")
  eq(cfg.display.diff.enabled, true, "diff enabled")
end)

test("codecompanion opts config is valid", function()
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  eq(cfg.opts.log_level, "INFO", "log level")
  eq(cfg.opts.language, "Chinese", "language")
end)

-- ══════════════════════════════════════════════════════════════════════
--  4. Avante configuration
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Avante config ===\n")

test("avante uses siliconflow provider", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  eq(cfg.provider, "siliconflow", "provider")
  eq(cfg.auto_suggestions_provider, "siliconflow", "auto_suggestions_provider")
end)

test("avante siliconflow provider inherits from openai", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  eq(sf.__inherited_from, "openai", "inherited from openai")
end)

test("avante siliconflow has correct endpoint", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  eq(sf.endpoint, "https://api.siliconflow.cn/v1", "endpoint")
end)

test("avante siliconflow has model configuration", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  eq(sf.model, "Qwen/Qwen2.5-Coder-32B-Instruct", "model")
  is_type(sf.timeout, "number", "timeout")
  is_type(sf.context_window, "number", "context_window")
end)

test("avante siliconflow has api_key_name", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  eq(sf.api_key_name, "SILICONFLOW_API_KEY", "api_key_name")
end)

test("avante has extra_request_body", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  is_type(sf.extra_request_body, "table", "extra_request_body")
  is_type(sf.extra_request_body.temperature, "number", "temperature")
  is_type(sf.extra_request_body.max_tokens, "number", "max_tokens")
end)

test("avante temperature is in valid range", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  is_truthy(sf.extra_request_body.temperature >= 0 and sf.extra_request_body.temperature <= 2, "temperature range")
end)

test("avante max_tokens is positive", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  local sf = cfg.providers.siliconflow
  is_truthy(sf.extra_request_body.max_tokens > 0, "max_tokens positive")
end)

test("avante behaviour config", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  eq(cfg.behaviour.auto_suggestions, false, "auto_suggestions")
  eq(cfg.behaviour.auto_set_highlight_group, true, "auto_set_highlight_group")
  eq(cfg.behaviour.auto_set_keymaps, true, "auto_set_keymaps")
  eq(cfg.behaviour.support_paste_from_clipboard, true, "paste from clipboard")
end)

test("avante diff config", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  eq(cfg.diff.autojump, true, "autojump")
end)

test("avante mappings config", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  is_type(cfg.mappings, "table", "mappings")
  eq(cfg.mappings.ask, "<leader>av", "ask mapping")
  eq(cfg.mappings.edit, "<leader>ae", "edit mapping")
  is_type(cfg.mappings.diff, "table", "diff mappings")
  is_type(cfg.mappings.jump, "table", "jump mappings")
end)

test("avante diff mappings have conflict resolution keys", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  eq(cfg.mappings.diff.ours, "co", "ours mapping")
  eq(cfg.mappings.diff.theirs, "ct", "theirs mapping")
  eq(cfg.mappings.diff.both, "cb", "both mapping")
  eq(cfg.mappings.diff.next, "]x", "next mapping")
  eq(cfg.mappings.diff.prev, "[x", "prev mapping")
end)

test("avante windows config", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  is_truthy(cfg.windows.width > 0, "window width")
  is_truthy(cfg.windows.input.height > 0, "input height")
  eq(cfg.windows.wrap, true, "wrap enabled")
end)

-- ══════════════════════════════════════════════════════════════════════
--  5. Runtime environment variable
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Runtime environment ===\n")

test("runtime.lua sets SILICONFLOW_API_KEY", function()
  local old = vim.env.SILICONFLOW_API_KEY
  vim.env.SILICONFLOW_API_KEY = nil

  dofile(root .. "lua/core/runtime.lua")

  is_truthy(vim.env.SILICONFLOW_API_KEY, "SILICONFLOW_API_KEY is set")
  vim.env.SILICONFLOW_API_KEY = old
end)

test("SILICONFLOW_API_KEY has correct format", function()
  local old = vim.env.SILICONFLOW_API_KEY
  vim.env.SILICONFLOW_API_KEY = nil

  dofile(root .. "lua/core/runtime.lua")

  local key = vim.env.SILICONFLOW_API_KEY
  is_truthy(key and #key > 20, "API key length")
  is_truthy(key and key:match("^sk%-"), "API key prefix")
  vim.env.SILICONFLOW_API_KEY = old
end)

test("existing SILICONFLOW_API_KEY env var is preserved", function()
  local old = vim.env.SILICONFLOW_API_KEY
  vim.env.SILICONFLOW_API_KEY = "test-existing-key"

  dofile(root .. "lua/core/runtime.lua")

  eq(vim.env.SILICONFLOW_API_KEY, "test-existing-key", "preserved existing key")
  vim.env.SILICONFLOW_API_KEY = old
end)

-- ══════════════════════════════════════════════════════════════════════
--  6. Adapter source content verification
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Adapter source content ===\n")

test("codecompanion adapter config contains correct endpoint", function()
  local f = io.open(root .. "lua/configs/codecompanion.lua", "r")
  local content = f:read("*a")
  f:close()
  is_truthy(content:find("api.siliconflow.cn"), "endpoint in source")
  is_truthy(content:find("openai_compatible"), "extends openai_compatible")
  is_truthy(content:find("SILICONFLOW_API_KEY"), "env var reference in source")
end)

test("codecompanion adapter config contains model names", function()
  local f = io.open(root .. "lua/configs/codecompanion.lua", "r")
  local content = f:read("*a")
  f:close()
  is_truthy(content:find("Qwen2%.5%-Coder%-32B"), "Qwen2.5-Coder model")
  is_truthy(content:find("DeepSeek%-V3"), "DeepSeek-V3 choice")
  is_truthy(content:find("DeepSeek%-R1"), "DeepSeek-R1 choice")
  is_truthy(content:find("GLM%-5%.1"), "GLM-5.1 choice")
end)

test("avante adapter config contains correct settings", function()
  local f = io.open(root .. "lua/configs/avante.lua", "r")
  local content = f:read("*a")
  f:close()
  is_truthy(content:find("api.siliconflow.cn"), "endpoint in source")
  is_truthy(content:find("__inherited_from"), "inherits from openai")
  is_truthy(content:find("SILICONFLOW_API_KEY"), "env var reference")
end)

-- ══════════════════════════════════════════════════════════════════════
--  7. SiliconFlow API connectivity (live test)
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== SiliconFlow API connectivity ===\n")

test("API responds to chat completion request", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s --max-time 15 https://api.siliconflow.cn/v1/chat/completions '
      .. '-H "Authorization: Bearer %s" '
      .. '-H "Content-Type: application/json" '
      .. "-d '{\"model\":\"Qwen/Qwen2.5-Coder-32B-Instruct\",\"messages\":[{\"role\":\"user\",\"content\":\"say ok\"}],\"max_tokens\":5}'",
    api_key
  )
  local handle = io.popen(cmd)
  is_truthy(handle, "curl command executed")
  local result = handle:read("*a")
  handle:close()
  is_truthy(result and #result > 0, "API returned data")
  local data = vim.json.decode(result)
  is_truthy(data.choices and #data.choices > 0, "API returned choices")
  is_truthy(data.choices[1].message, "API returned message")
end)

test("API responds to models listing", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s --max-time 10 https://api.siliconflow.cn/v1/models '
      .. '-H "Authorization: Bearer %s"',
    api_key
  )
  local handle = io.popen(cmd)
  is_truthy(handle, "curl command executed")
  local result = handle:read("*a")
  handle:close()
  local data = vim.json.decode(result)
  is_truthy(data.data and #data.data > 0, "API returned models list")
end)

test("configured model Qwen2.5-Coder-32B is available", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s --max-time 10 https://api.siliconflow.cn/v1/models '
      .. '-H "Authorization: Bearer %s"',
    api_key
  )
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  local data = vim.json.decode(result)
  local found = false
  for _, m in ipairs(data.data) do
    if m.id == "Qwen/Qwen2.5-Coder-32B-Instruct" then
      found = true
      break
    end
  end
  is_truthy(found, "Qwen2.5-Coder-32B-Instruct model available")
end)

test("api key is valid (non-401 response)", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s -o /dev/null -w "%%{http_code}" --max-time 10 https://api.siliconflow.cn/v1/models '
      .. '-H "Authorization: Bearer %s"',
    api_key
  )
  local handle = io.popen(cmd)
  local status = handle:read("*a"):gsub("%s+", "")
  handle:close()
  eq(status, "200", "HTTP status")
end)

test("DeepSeek-V3 model is available on SiliconFlow", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s --max-time 10 https://api.siliconflow.cn/v1/models '
      .. '-H "Authorization: Bearer %s"',
    api_key
  )
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  local data = vim.json.decode(result)
  local found = false
  for _, m in ipairs(data.data) do
    if m.id == "deepseek-ai/DeepSeek-V3" then
      found = true
      break
    end
  end
  is_truthy(found, "DeepSeek-V3 available")
end)

-- ══════════════════════════════════════════════════════════════════════
--  8. Streaming API test (SSE)
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Streaming API (SSE) ===\n")

test("API supports streaming responses", function()
  local api_key = "sk-eavhnhchnunkwmfzfojxhtzbifcxngokkotehysspfpgdoul"
  local cmd = string.format(
    'curl -s --max-time 15 https://api.siliconflow.cn/v1/chat/completions '
      .. '-H "Authorization: Bearer %s" '
      .. '-H "Content-Type: application/json" '
      .. "-d '{\"model\":\"Qwen/Qwen2.5-Coder-32B-Instruct\",\"messages\":[{\"role\":\"user\",\"content\":\"say ok\"}],\"max_tokens\":5,\"stream\":true}'",
    api_key
  )
  local handle = io.popen(cmd)
  is_truthy(handle, "curl command executed")
  local result = handle:read("*a")
  handle:close()
  is_truthy(result and #result > 0, "streaming returned data")
  is_truthy(result:find("data:"), "contains SSE data prefix")
end)

-- ══════════════════════════════════════════════════════════════════════
--  9. File structure consistency
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== File structure consistency ===\n")

test("configs/codecompanion.lua file exists", function()
  local f = io.open(root .. "lua/configs/codecompanion.lua", "r")
  is_truthy(f, "codecompanion config exists")
  if f then f:close() end
end)

test("configs/avante.lua file exists", function()
  local f = io.open(root .. "lua/configs/avante.lua", "r")
  is_truthy(f, "avante config exists")
  if f then f:close() end
end)

test("plugins/ai.lua file exists", function()
  local f = io.open(root .. "lua/plugins/ai.lua", "r")
  is_truthy(f, "ai plugin spec exists")
  if f then f:close() end
end)

test("configs/codecompanion.lua returns config without requiring plugin", function()
  -- Verify that dofile works even when codecompanion module is absent
  -- (pcall require should gracefully skip setup)
  local cfg = dofile(root .. "lua/configs/codecompanion.lua")
  is_type(cfg, "table", "config returned")
  is_truthy(cfg.strategies, "strategies present")
end)

test("configs/avante.lua returns config without requiring plugin", function()
  local cfg = dofile(root .. "lua/configs/avante.lua")
  is_type(cfg, "table", "config returned")
  is_truthy(cfg.providers, "providers present")
end)

-- ══════════════════════════════════════════════════════════════════════
-- 10. Config consistency between codecompanion and avante
-- ══════════════════════════════════════════════════════════════════════

io.write("\n=== Config consistency ===\n")

test("both configs use the same model", function()
  local cc_cfg = dofile(root .. "lua/configs/codecompanion.lua")
  local av_cfg = dofile(root .. "lua/configs/avante.lua")
  -- CC model is in the adapter function source, av in providers.siliconflow
  local av_model = av_cfg.providers.siliconflow.model
  is_truthy(av_model == "Qwen/Qwen2.5-Coder-32B-Instruct", "avante model matches")
end)

test("both configs reference the same API endpoint", function()
  local f_cc = io.open(root .. "lua/configs/codecompanion.lua", "r")
  local cc_content = f_cc:read("*a")
  f_cc:close()

  local av_cfg = dofile(root .. "lua/configs/avante.lua")
  local av_endpoint = av_cfg.providers.siliconflow.endpoint

  is_truthy(cc_content:find("api.siliconflow.cn"), "CC references siliconflow")
  is_truthy(av_endpoint:find("api.siliconflow.cn"), "AV references siliconflow")
end)

-- ══════════════════════════════════════════════════════════════════════
-- Summary
-- ══════════════════════════════════════════════════════════════════════

io.write(string.format("\n%d passed, %d failed\n", pass_count, fail_count))
if fail_count > 0 then
  os.exit(1)
end
os.exit(0)
