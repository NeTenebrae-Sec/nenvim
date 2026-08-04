local ok_cmp, cmp = pcall(require, "cmp")
if not ok_cmp then
  return
end

pcall(require, "plugins.lsp.cmp.luasnip")

-- Cacheamos LuaSnip arriba una sola vez para rendimiento máximo
local ok_luasnip, luasnip = pcall(require, "luasnip")
local ok_html_ids, html_ids = pcall(require, "plugins.lsp.cmp.html_ids")
if ok_html_ids then
  html_ids.setup()
end

cmp.setup({
  performance = {
    max_view_entries = 12, -- Evita menús gigantescos que tapen el código
    fetching_timeout = 200, -- Si el LSP tarda, no congela tu escritura
    debounce = 60,
    throttle = 30,
    filtering_context_budget = 3,
    confirm_resolve_timeout = 80,
    async_budget = 1,
  },

  completion = {
    completeopt = "menu,menuone,noinsert",
  },

  matching = {
    disallow_symbol_nonprefix_matching = false,
    disallow_fuzzy_matching = false,
    disallow_fullfuzzy_matching = false,
    disallow_partial_fuzzy_matching = false,
    disallow_partial_matching = false,
    disallow_prefix_unmatching = false,
  },

  window = {
    completion = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
      col_offset = -3,
      side_padding = 1,
    }),
    documentation = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
    }),
  },

  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, vim_item)
      -- Diccionario nativo de iconos
      local kind_icons = {
        Text = "󰉿",
        Method = "󰆧",
        Function = "󰊕",
        Constructor = "",
        Field = "󰜢",
        Variable = "󰀫",
        Class = "󰠱",
        Interface = "󱤊",
        Module = "",
        Property = "󰜢",
        Unit = "󰑭",
        Value = "󰎨",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "󰩫",
        Color = "󰏘",
        File = "󰈙",
        Reference = "󰈚",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "󰙅",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰅲",
      }

      vim_item.kind = string.format(" %s ", kind_icons[vim_item.kind] or "")
      -- Etiquetas estéticas y ordenadas para el lado derecho
      local menus = {
        nvim_lsp = "󰅩 LSP",
        path = "󰉋 Path",
        buffer = "󰦨 Buf",
        luasnip = "󰩫 Snip",
        html_ids = "󰩨 HTML-ID",
      }

      vim_item.menu = menus[entry.source.name] or entry.source.name

      vim_item.abbr = vim_item.abbr .. "    "

      return vim_item
    end,
  },

  snippet = {
    expand = function(args)
      if ok_luasnip then
        luasnip.lsp_expand(args.body)
      end
    end,
  },

  sources = cmp.config.sources({
    { name = "nvim_lsp", priority = 1000 },
    { name = "luasnip", priority = 750 },
    { name = "path", priority = 500 },
    { name = "html_ids", priority = 600 },
  }, {
    {
      name = "buffer",
      priority = 250,
      option = {
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end,
      },
    },
  }),
})
