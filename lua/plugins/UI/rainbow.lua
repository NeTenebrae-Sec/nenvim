-- =========================================================
-- RAINBOW DELIMITERS (Optimizado y Corregido)
-- =========================================================

local ok, rainbow = pcall(require, "rainbow-delimiters")
if not ok then
  return
end

-- Usamos las estrategias directamente de la variable 'rainbow' que validamos arriba
local global_strategy = rainbow.strategy["global"]

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
