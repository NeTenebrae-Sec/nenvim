-- =========================================================
-- Ficha React — sobre node-ts (vtsls/oxlint/prettier/emmet)
-- =========================================================
-- Sin lsp/lint/format propios: jsx/tsx los cubre node-ts (sin
-- duplicar diagnósticos). Aporta el runner de proyecto vite/react.

local M = {
  name = "react",
  filetypes = { "javascriptreact", "typescriptreact" },

  -- run(): menú vite (dev/build/preview) si el proyecto tiene react;
  -- fallback node para archivos sueltos. detect() resuelve el runner
  -- por delante de nextjs/node-ts en jsx/tsx.
  dap = require("languages.react.dap"),
}

return M
