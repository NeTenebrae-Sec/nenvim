-- =========================================================
-- lua/plugins/UI/devicons.lua
-- Configuración de nvim-web-devicons (Catálogo por defecto)
-- =========================================================

local status, devicons = pcall(require, "nvim-web-devicons")
if not status then
  return
end

devicons.setup({
  override = {},

  default = true,
})
