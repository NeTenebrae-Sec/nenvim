-- =========================================================
-- Rainbow delimiters propio (reemplaza rainbow-delimiters.nvim
-- — tarea 012 Fase 2). Recorre el árbol treesitter, asigna
-- profundidad a los delimitadores con una pila y los colorea
-- con extmarks en ciclo de 7 grupos. Guard de tamaño 009.
-- =========================================================

local api = vim.api

local M = {}

local ns = api.nvim_create_namespace("nete.rainbow")

local MAX_LINES = 3000
local DEBOUNCE = 200

local DELIMS = {
  ["("] = true, [")"] = true,
  ["{"] = true, ["}"] = true,
  ["["] = true, ["]"] = true,
  ["<"] = true, [">"] = true,
}

local GROUPS = {
  "RainbowDelimiterRed",
  "RainbowDelimiterYellow",
  "RainbowDelimiterBlue",
  "RainbowDelimiterOrange",
  "RainbowDelimiterGreen",
  "RainbowDelimiterViolet",
  "RainbowDelimiterCyan",
}

-- Colores por defecto (paridad cromática con el plugin previo)
api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#e62e4d", default = true })
api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#d99b43", default = true })
api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#4ba3db", default = true })
api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#c26d42", default = true })
api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#4fa36a", default = true })
api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#9b51e0", default = true })
api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#a0cded", default = true })

local timers = {}
local attached = {}

local function walk(node, bufnr)
  local stack = {}
  local function recurse(n)
    for child in n:iter_children() do
      local t = child:type()
      if DELIMS[t] then
        local opening = t == "(" or t == "{" or t == "[" or t == "<"
        if opening then
          stack[#stack + 1] = t
        end
        local depth = #stack
        local g = GROUPS[(depth - 1) % #GROUPS + 1]
        local srow, scol, erow, ecol = child:range()
        pcall(api.nvim_buf_set_extmark, bufnr, ns, srow, scol, {
          end_row = erow,
          end_col = ecol,
          hl_group = g,
          hl_mode = "combine",
          priority = 110,
        })
        if not opening and #stack > 0 then
          table.remove(stack)
        end
      elseif child:child_count() > 0 then
        recurse(child)
      end
    end
  end
  recurse(node)
end

local function update(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not attached[bufnr] then
    return
  end
  if api.nvim_buf_line_count(bufnr) > MAX_LINES then
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return
  end

  local parsed = pcall(parser.parse, parser)
  if not parsed then
    return
  end

  pcall(api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
  for _, tree in ipairs(parser:trees()) do
    walk(tree:root(), bufnr)
  end
end

local function schedule_update(bufnr)
  local old = timers[bufnr]
  timers[bufnr] = nil
  if old and not old:is_closing() then
    old:stop()
    old:close()
  end
  local t = vim.uv.new_timer()
  timers[bufnr] = t
  t:start(DEBOUNCE, 0, vim.schedule_wrap(function()
    timers[bufnr] = nil
    if not t:is_closing() then
      t:stop()
      t:close()
    end
    update(bufnr)
  end))
end

local function attach(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    return
  end
  if api.nvim_buf_line_count(bufnr) > MAX_LINES then
    return
  end
  local ok = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then
    return
  end
  attached[bufnr] = true
  schedule_update(bufnr)
end

local group = api.nvim_create_augroup("NvimRainbow", { clear = true })
for _, ev in ipairs({ "BufEnter", "FileType", "TextChanged", "TextChangedI", "InsertLeave", "BufWritePost" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function(args)
      if attached[args.buf] then
        schedule_update(args.buf)
      else
        attach(args.buf)
      end
    end,
  })
end
api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    attached[args.buf] = nil
    local t = timers[args.buf]
    timers[args.buf] = nil
    if t and not t:is_closing() then
      t:stop()
      t:close()
    end
    pcall(api.nvim_buf_clear_namespace, args.buf, ns, 0, -1)
  end,
})

return M
