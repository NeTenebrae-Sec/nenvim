-- =========================================================
-- Ficha Bash/Shell — shfmt + bash-debug-adapter
-- =========================================================
-- Sin LSP (paridad con la config anterior: bash-language-server
-- estaba en mason pero nunca cableado).

local M = {
  name = "bash",
  filetypes = { "bash", "sh", "zsh" },

  format_modules = { "languages.bash.format" },

  parsers = { "bash" },

  tools = { "shfmt", "bash-debug-adapter" },

  dap = require("languages.bash.dap"),
}

return M
