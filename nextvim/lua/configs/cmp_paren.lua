local M = {}

local function trim(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function collect_top_level_ops(expr)
  local ops = {}
  local i = 1
  local depth = 0
  local in_single = false
  local in_double = false
  local op_tokens = { "//", "**", "<<", ">>", "+", "-", "*", "/", "%", "|", "&", "^" }

  while i <= #expr do
    local ch = expr:sub(i, i)
    local prev = i > 1 and expr:sub(i - 1, i - 1) or ""

    if in_single then
      if ch == "'" and prev ~= "\\" then
        in_single = false
      end
      i = i + 1
    elseif in_double then
      if ch == '"' and prev ~= "\\" then
        in_double = false
      end
      i = i + 1
    else
      if ch == "'" then
        in_single = true
        i = i + 1
      elseif ch == '"' then
        in_double = true
        i = i + 1
      elseif ch == "(" or ch == "[" or ch == "{" then
        depth = depth + 1
        i = i + 1
      elseif ch == ")" or ch == "]" or ch == "}" then
        depth = math.max(depth - 1, 0)
        i = i + 1
      else
        local matched = false
        for _, op in ipairs(op_tokens) do
          if expr:sub(i, i + #op - 1) == op then
            table.insert(ops, { end_col = i + #op - 1, depth = depth })
            i = i + #op
            matched = true
            break
          end
        end
        if not matched then
          i = i + 1
        end
      end
    end
  end

  local base_depth = depth
  local filtered = {}
  for _, op in ipairs(ops) do
    if op.depth == base_depth then
      table.insert(filtered, { end_col = op.end_col })
    end
  end
  return filtered
end

local function wrap_last_n_operands(expr, n)
  local source = trim(expr)
  if source == "" then
    return source
  end

  local ops = collect_top_level_ops(source)
  local operator_count = #ops
  local operand_count = operator_count + 1

  if operator_count == 0 or n >= operand_count then
    return "(" .. source .. ")"
  end

  local boundary_op = ops[operator_count - n + 1]
  local left = trim(source:sub(1, boundary_op.end_col))
  local right = trim(source:sub(boundary_op.end_col + 1))
  return left .. "(" .. right .. ")"
end

local function effective_distance(expr, typed_count)
  local source = trim(expr)
  if typed_count > 1 and source:sub(-1) == ")" then
    return typed_count - 1
  end
  return typed_count
end

local function parse_suffix_at_end(before_line)
  local expr, parens = before_line:match("^(.-)%.([)]*)$")
  if not expr or parens == nil then
    return nil, nil, nil
  end
  return expr, #parens, ""
end

local function parse_suffix_anywhere(before_line)
  local expr, parens, tail = before_line:match("^(.*)%.([)]*)(.*)$")
  if not expr or parens == nil then
    return nil, nil, nil
  end
  -- Prevent accidental expansion on `a. ` / `a.\t` etc.
  -- Empty paren suffix is only valid when cursor is exactly after dot.
  if parens == "" and tail ~= "" then
    return nil, nil, nil
  end
  return expr, #parens, tail or ""
end

function M.expand_inline(before_line)
  -- Expand only when cursor is immediately after suffix token.
  -- This avoids accidental expansion like `1.) <Enter>`.
  local expr, count = parse_suffix_at_end(before_line)
  if not expr then
    return nil
  end
  local typed = math.max(count, 1)
  if trim(expr) == "" then
    return nil
  end
  return wrap_last_n_operands(expr, effective_distance(expr, typed))
end

function M.has_suffix_at_end(before_line)
  local expr, count = parse_suffix_at_end(before_line)
  return expr ~= nil and count ~= nil and trim(expr) ~= ""
end

function M.setup()
  local cmp = require("cmp")
  local source = {}
  source.new = function()
    return setmetatable({}, { __index = source })
  end

  function source:is_available()
    return vim.bo.filetype == "python"
  end

  function source:get_trigger_characters()
    return { ".", ")" }
  end

  function source:get_keyword_pattern()
    -- Match suffix token like `.`, `.)`, `.))`, `.)))`.
    return [[\.[)]*]]
  end

  function source:complete(params, callback)
    local before = params.context.cursor_before_line
    local expr, typed_count = parse_suffix_at_end(before)
    if not expr then
      callback({ items = {}, isIncomplete = false })
      return
    end

    local items = {}
    local start_n = math.max(typed_count, 1)
    for n = start_n, 5 do
      local trigger = "." .. string.rep(")", n)
      local distance = effective_distance(expr, n)
      table.insert(items, {
        label = trigger,
        kind = cmp.lsp.CompletionItemKind.Snippet,
        detail = ("Wrap last %d operand(s)"):format(distance),
        insertTextFormat = 1,
        filterText = trigger,
        sortText = string.format("%02d", n),
        textEdit = {
          range = {
            start = { line = params.context.cursor.row - 1, character = 0 },
            ["end"] = { line = params.context.cursor.row - 1, character = #before },
          },
          newText = wrap_last_n_operands(expr, distance),
        },
      })
    end

    callback({ items = items, isIncomplete = false })
  end

  cmp.register_source("paren_wrap", source.new())
end

return M
