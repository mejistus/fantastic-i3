local M = {}

local patched = false

local function sanitize_symbol_container_names(symbols)
  for _, symbol in ipairs(symbols or {}) do
    if symbol.containerName ~= nil and type(symbol.containerName) ~= "string" then
      symbol.containerName = nil
    end

    if symbol.children then
      sanitize_symbol_container_names(symbol.children)
    end
  end
end

function M.patch_symbols_to_items()
  if patched then
    return
  end

  patched = true
  local original = vim.lsp.util.symbols_to_items

  vim.lsp.util.symbols_to_items = function(symbols, ...)
    sanitize_symbol_container_names(symbols)
    return original(symbols, ...)
  end
end

return M
