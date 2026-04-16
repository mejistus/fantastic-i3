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
        if depth == 0 then
          for _, op in ipairs(op_tokens) do
            if expr:sub(i, i + #op - 1) == op then
              table.insert(ops, { end_col = i + #op - 1 })
              i = i + #op
              matched = true
              break
            end
          end
        end
        if not matched then
          i = i + 1
        end
      end
    end
  end

  return ops
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

local function parse_suffix(before_line)
  local expr, parens = before_line:match("^(.-)%.([)]+)$")
  if not expr or not parens then
    return nil, nil
  end
  return expr, #parens
end

function M.expand_inline(before_line)
  local expr, count = parse_suffix(before_line)
  if not expr then
    return nil
  end
  return wrap_last_n_operands(expr, count)
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
    return { ")" }
  end

  function source:get_keyword_pattern()
    -- Match only the suffix token like `.)`, `.))`, `.)))` so cmp can keep our items.
    return [[\.[)]\+]]
  end

  function source:complete(params, callback)
    local before = params.context.cursor_before_line
    local expr, typed_count = parse_suffix(before)
    if not expr then
      callback({ items = {}, isIncomplete = false })
      return
    end

    local items = {}
    for n = typed_count, 5 do
      local trigger = "." .. string.rep(")", n)
      table.insert(items, {
        label = trigger,
        kind = cmp.lsp.CompletionItemKind.Snippet,
        detail = ("Wrap last %d operand(s)"):format(n),
        insertTextFormat = 1,
        filterText = trigger,
        sortText = string.format("%02d", n),
        textEdit = {
          range = {
            start = { line = params.context.cursor.row - 1, character = 0 },
            ["end"] = { line = params.context.cursor.row - 1, character = #before },
          },
          newText = wrap_last_n_operands(expr, n),
        },
      })
    end

    callback({ items = items, isIncomplete = false })
  end

  cmp.register_source("paren_wrap", source.new())
end

return M
