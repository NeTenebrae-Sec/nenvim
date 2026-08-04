-- =========================================================
-- lua/plugins/lsp/formatters/generic.lua
-- Lenguajes con formateadores por defecto (Python, C/C++, Java, TOML)
-- =========================================================

return {
  formatters_by_ft = {
    python = { "isort", "black" },
    toml = { "taplo" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    java = { "google-java-format" },
  },
}
