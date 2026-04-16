local cmp = require("cmp")
local luasnip = require("luasnip")
local paren_wrap = require("configs.cmp_paren")

require("codeium").setup({
  enable_cmp_source = true,
  virtual_text = {
    enabled = true,
    filetypes = { "python", "tex", "markdown" },
    default_filetype_enabled = true,
    idle_delay = 500,
  },
})

cmp.setup({
  formatting = {
    format = function(entry, vim_item)
      return vim_item
    end,
  },
  completion = {
    autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
    keyword_length = 1,
    debounce = 750,
    keyword_pattern = [[\S+]],
  },
  mapping = {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
        return
      end
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()
      local before = line:sub(1, col)
      local expanded = (vim.bo.filetype == "python") and paren_wrap.expand_inline(before) or nil
      if expanded then
        vim.api.nvim_set_current_line(expanded .. line:sub(col + 1))
        vim.api.nvim_win_set_cursor(0, { row, #expanded })
        return
      end
      fallback()
    end, { "i", "s" }),
    ["<Up>"] = cmp.mapping.select_prev_item(),
    ["<Down>"] = cmp.mapping.select_next_item(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()
      local before = line:sub(1, col)
      local expanded = (vim.bo.filetype == "python") and paren_wrap.expand_inline(before) or nil

      if expanded then
        vim.api.nvim_set_current_line(expanded .. line:sub(col + 1))
        vim.api.nvim_win_set_cursor(0, { row, #expanded })
        return
      elseif cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    {
      name = "luasnip",
      option = {
        show_autosnippets = true,
      },
    },
    { name = "codeium" },
    { name = "buffer" },
    { name = "path" },
  }),
})
