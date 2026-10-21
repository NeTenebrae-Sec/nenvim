local M = {}

function M.setup(c, set)
  set("Pmenu", { fg = c.fg1, bg = c.bg2 })
  set("PmenuSel", { fg = c.bg0, bg = c.cyan1, bold = true })

  set("CmpItemKindMethod", { fg = c.cyan2, bold = true })
  set("CmpItemKindFunction", { fg = c.cyan2, bold = true })
  set("CmpItemKindConstructor", { fg = c.cyan1 })
  set("CmpItemKindVariable", { fg = c.teal })
  set("CmpItemKindField", { fg = c.teal })
  set("CmpItemKindProperty", { fg = c.teal })
  set("CmpItemKindClass", { fg = c.purple, bold = true })
  set("CmpItemKindInterface", { fg = c.purple })
  set("CmpItemKindStruct", { fg = c.purple })
  set("CmpItemKindEnum", { fg = c.purple })
  set("CmpItemKindEnumMember", { fg = c.blue })
  set("CmpItemKindKeyword", { fg = c.cyan1, bold = true })
  set("CmpItemKindSnippet", { fg = c.ice })
  set("CmpItemKindFile", { fg = c.fg1 })
  set("CmpItemKindFolder", { fg = c.border })

  -- Noice Autocompletado (Existente)
  set("NoiceCompletionItemKindFunction", { link = "CmpItemKindFunction" })
  set("NoiceCompletionItemKindMethod", { link = "CmpItemKindMethod" })
  set("NoiceCompletionItemKindVariable", { link = "CmpItemKindVariable" })
  set("NoiceCompletionItemKindKeyword", { link = "CmpItemKindKeyword" })
  set("NoiceCompletionItemKindProperty", { link = "CmpItemKindProperty" })

  -- =======================================================
  -- NOICE POPUPS Y BÚSQUEDA (CORRECCIÓN AMARILLO)
  -- =======================================================
  -- Cuando presionas "/" (Búsqueda) -> Todo Cyan Eléctrico
  set("NoiceCmdlinePopupBorderSearch", { fg = c.cyan1, bg = "NONE" })
  set("NoiceCmdlinePopupTitleSearch", { fg = c.cyan1, bold = true })

  -- Cuando presionas ":" (Comandos normales) -> Rosa/Rojo Neón
  set("NoiceCmdlinePopupBorder", { fg = c.red_neon, bg = "NONE" })
  set("NoiceCmdlinePopupTitle", { fg = c.red_neon, bold = true })

  -- El fondo e input de la caja de texto flotante de Noice
  set("NoiceCmdline", { fg = c.fg0, bg = c.bg2 })
  set("NoiceCmdlinePrompt", { fg = c.cyan1, bold = true })

  -- =======================================================
  -- TABLINE (propia — reemplaza bufferline, tarea 012)
  -- =======================================================
  set("TabLine", { fg = c.fg2, bg = c.bg1 })
  set("TabLineSel", { fg = c.white, bg = c.bg2, bold = true })
  set("TabLineFill", { bg = c.bg0 })

  -- =======================================================
  -- SNACKS DASHBOARD
  -- =======================================================
  set("SnacksDashboardHeader", { fg = c.cyan1 })
  set("SnacksDashboardTitle", { fg = c.cyan2, bold = true })
  set("SnacksDashboardIcon", { fg = c.ice })
  set("SnacksDashboardDesc", { fg = c.fg2 })
  set("SnacksDashboardKey", { fg = c.purple })
  set("SnacksDashboardFile", { fg = c.fg1 })
  set("SnacksDashboardDir", { fg = c.fg2 })

  -- =======================================================
  -- LAZY
  -- =======================================================
  set("LazyNormal", { fg = c.fg0, bg = c.bg2 })
  set("LazyButton", { fg = c.fg1, bg = c.bg3 })
  set("LazyButtonActive", { fg = c.white, bg = c.deep, bold = true })
  set("LazyH1", { fg = c.bg0, bg = c.cyan1, bold = true })

  -- =======================================================
  -- FLASH
  -- =======================================================
  set("FlashMatch", { fg = c.ice, bg = c.deep, bold = true })
  set("FlashCurrent", { fg = c.bg0, bg = c.cyan1, bold = true })
  set("FlashLabel", { fg = c.bg0, bg = c.pink, bold = true })
  set("FlashBackdrop", { fg = c.fg2 })
end

return M
