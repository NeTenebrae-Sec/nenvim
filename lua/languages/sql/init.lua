-- =========================================================
-- Ficha SQL — multi-motor (PostgreSQL / MySQL / MongoDB)
-- =========================================================
-- El aux server.lua gestiona el ciclo de vida: dialecto por proyecto
-- (:SqlDialect), arranque por buffer (postgres_lsp / sqlls),
-- :SqlInit / :MongoInit y registro de filetypes auxiliares.

local M = {
  name = "sql",
  filetypes = { "sql", "mysql", "mongosh" },

  -- Sin `lsp`: el aux arranca los servidores con vim.lsp.start según
  -- el dialecto del proyecto (un solo servidor activo por buffer)

  format_modules = { "languages.sql.format" },

  parsers = { "sql" },

  tools = { "postgres-language-server", "sqlls", "sqlfluff" },
}

-- Side effects: autocmds, comandos :SqlDialect/:SqlInit/:MongoInit,
-- filetypes mongo y registro del parser sql para mysql/mongosh
pcall(require, "languages.sql.server")

return M
