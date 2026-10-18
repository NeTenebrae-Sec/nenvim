-- =========================================================
-- RAINBOW DELIMITERS (Optimizado y Corregido)
-- =========================================================

local ok, rainbow = pcall(require, "rainbow-delimiters")
if not ok then
  return
end

-- Usamos las estrategias directamente de la variable 'rainbow' que validamos arriba
local global_strategy = rainbow.strategy["global"]

-- Guard 009: la strategy global recorre TODOS los nodos del árbol en Lua a
-- cada parse completo con coste cuadrático (2k líneas ≈140ms, 10k ≈3.3s,
-- 50k ≈97s → congelaba el editor en archivos medianos). Por encima de
-- MAX_LINES no se engancha (sin colores rainbow en ese buffer; el resto
-- —LSP, treesitter, lint— sigue activo). rainbow.strategy["global"] puede
-- ser el nombre del módulo (string); el objeto real es el módulo cacheado
-- en require, y sobre él se aplica el wrap (require lo resuelve igual).
local MAX_LINES = 3000
local strat_ref = global_strategy
if type(strat_ref) == "string" then
  local okm, m = pcall(require, strat_ref)
  if okm then
    strat_ref = m
  end
end
if type(strat_ref) == "table" then
  local raw_attach = strat_ref.on_attach
  local raw_reset = strat_ref.on_reset
  strat_ref.on_attach = function(bufnr, settings)
    if vim.api.nvim_buf_line_count(bufnr) > MAX_LINES then
      return
    end
    raw_attach(bufnr, settings)
  end
  strat_ref.on_reset = function(bufnr, settings)
    if vim.api.nvim_buf_line_count(bufnr) > MAX_LINES then
      return
    end
    raw_reset(bufnr, settings)
  end
end

vim.g.rainbow_delimiters = {
  strategy = {
    -- Si por alguna razón la estrategia global no carga, usamos una función vacía como fallback
    [""] = global_strategy or function() end,
    lua = global_strategy or function() end,
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-delimiters", -- Volvemos a las llaves normales eliminando rainbow-blocks
    html = "rainbow-tags",
    javascriptreact = "rainbow-tags",
    typescriptreact = "rainbow-tags",
  },
  priority = {
    [""] = 110,
    lua = 110,
    html = 210,
    javascriptreact = 210,
    typescriptreact = 210,
  },
  highlight = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterCyan",
  },
}
