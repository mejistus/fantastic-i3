vim.env.SSL_CERT_DIR = vim.env.SSL_CERT_DIR or "/etc/ssl/certs"

local original_preview = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or "rounded"
  opts.max_width = opts.max_width or 80
  opts.max_height = opts.max_height or 20
  opts.winhighlight = opts.winhighlight or "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
  return original_preview(contents, syntax, opts, ...)
end

local original_notify = vim.notify
vim.notify = function(msg, level, notify_opts)
  if type(msg) == "string" and msg:match("Codeium") then
    return
  end
  return original_notify(msg, level, notify_opts)
end
