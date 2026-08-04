local M = {
  -- FONDOS / SUPERFICIES
  bg0 = "#05080a",
  bg1 = "#10171c",
  bg2 = "#172129",
  bg3 = "#22303b",
  bg4 = "#4c5e6c",
  border = "#245066",
  deep = "#103847",

  -- TEXTO BASE Y NEUTROS
  white = "#ffffff",
  fg0 = "#edf7fb",
  fg1 = "#c6dbe4",
  fg2 = "#88a1ae",
  fg3 = "#c7d7df",

  -- FAMILIA ROJO NEÓN / ROSA
  red_neon = "#ff007f",
  red_dark = "#ff66b2",
  red_return = "#d61958",
  pink = "#df4f89",
  pink_light = "#ff9ebb",
  purple = "#b15fe3",

  -- FAMILIA CYAN / MENTA / ACENTOS
  cyan_neon = "#19c2cf",
  cyan_soft = "#a7e6ee",
  ice = "#e0f7fa",
  mint_class = "#7ad7ae",
  lime_import = "#b2ea6d",
  teal_alt = "#36c69a",
  blue = "#158db0",

  -- LITERALES
  yellow_light = "#f06ca1",
  yellow = "#d2a24b",
  orange = "#3aae91",

  -- ALERTAS / ESTADOS
  error1 = "#ff6b78",
  error2 = "#d95763",
  warn1 = "#d6a43a",
  warn2 = "#b98a24",
}

-- Mapeos de compatibilidad interna
M.cyan1 = M.cyan_neon
M.cyan2 = M.cyan_soft
M.teal = M.teal_alt

return M
