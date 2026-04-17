local cmp = require("cmp")
local luasnip = require("luasnip")
local paren_wrap = require("configs.cmp_paren")

-- Set up suffix-style bracket completion (e.g. a+b+c.) => a+b+(c))
paren_wrap.setup()

require("codeium").setup({
  enable_cmp_source = true,
  virtual_text = {
    enabled = true,
    filetypes = { "python", "tex", "markdown" },
    default_filetype_enabled = true,
    idle_delay = 500,
  },
})

local ok_cmp_ap, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
if ok_cmp_ap then
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

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
  },
  mapping = {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping(function(fallback)
      if paren_wrap.is_active() then
        paren_wrap.confirm()
        return
      end
      if cmp.visible() then
        cmp.confirm({ select = true })
        return
      end
      fallback()
    end, { "i", "s" }),
    ["<Up>"] = cmp.mapping.select_prev_item(),
    ["<Down>"] = cmp.mapping.select_next_item(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
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
