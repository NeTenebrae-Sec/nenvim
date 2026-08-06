local M = {
  -- =======================================================
  -- FONDOS / SUPERFICIES (Fondo Negro Puro / Oscuro)
  -- =======================================================
  bg0 = "#05080a", -- Fondo principal
  bg1 = "#10171c", -- CursorLine / pestañas inactivas
  bg2 = "#172129", -- Ventanas flotantes / menús
  bg3 = "#22303b", -- Selección suave / resaltados
  bg4 = "#4c5e6c", -- Selección suave / resaltados
  border = "#245066", -- Bordes de paneles y ventanas
  deep = "#103847", -- Resaltado de MatchParen

  -- =======================================================
  -- TEXTO BASE Y NEUTROS
  -- =======================================================
  white = "#ffffff", -- Blanco brillante
  fg0 = "#edf7fb", -- Variables (Blanco muy limpio)
  fg1 = "#c6dbe4", -- Texto secundario discreto
  fg2 = "#88a1ae", -- Puntuación / Comentarios (Gris azulado apagado)
  fg3 = "#c7d7df",

  -- =======================================================
  -- FAMILIA ROJO NEÓN / ROSA (Keywords, Funciones, Salidas)
  -- =======================================================
  red_neon = "#ff007f", -- Rosa Neón Chicle (Se queda exclusivo para nombres de funciones/llamadas)
  red_dark = "#ff66b2", -- Operadores (Rosa pastel eléctrico)
  red_return = "#d61958", -- Rojo Rubí Eléctrico
  pink = "#df4f89", -- Atributos / Regex / Tags
  pink_light = "#ff9ebb", -- Rosa Pastel Claro (¡Nuevo! Exclusivo para Keywords estructurales)
  purple = "#b15fe3", -- Morado Neón
  -- =======================================================
  -- FAMILIA CYAN / MENTA / ACENTOS (Clases, Módulos, Strings)
  -- =======================================================
  cyan_neon = "#19c2cf", -- Cyan vivo (Equivale a tu antiguo cyan1)
  cyan_soft = "#a7e6ee", -- Strings / Cyan suave (Equivale a tu antiguo cyan2)
  ice = "#e0f7fa", -- Cyan helado ultra brillante (Nuevo)
  mint_class = "#7ad7ae", -- Clases y Estructuras (Menta Cyan)
  lime_import = "#b2ea6d", -- Imports/Exports (Misma rama, otra tonalidad)
  teal_alt = "#36c69a", -- Tonalidad alternativa para tags/markup (Equivale a teal)
  blue = "#158db0", -- Azul tecnológico de soporte (Nuevo)

  -- =======================================================
  -- LITERALES (Datos Duros)
  -- =======================================================
  yellow_light = "#f06ca1", -- Propiedades de objetos
  yellow = "#d2a24b", -- Booleanos (Amarillo)
  orange = "#3aae91", -- Números (Naranja/Verde tecnológico)

  -- =======================================================
  -- ALERTAS / ESTADOS
  -- =======================================================
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
