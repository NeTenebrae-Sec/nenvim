-- =========================================================
-- Ficha Next.js — sobre node-ts (vtsls/oxlint/prettier)
-- =========================================================
-- Sin lsp/lint propios (mismas razones que react: sin duplicados;
-- eslint-config-next se ejecuta vía `npm run lint`, paridad CLI).
-- Aporta el runner de proyecto next. En jsx/tsx su dap.detect()
-- (dep `next`) tiene prioridad sobre react en el runner.

local M = {
  name = "nextjs",
  filetypes = { "javascriptreact", "typescriptreact" },

  dap = require("languages.nextjs.dap"),
}

return M
