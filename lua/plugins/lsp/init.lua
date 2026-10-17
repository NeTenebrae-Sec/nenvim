-- =========================================================
-- Núcleo LSP (delgado): motor + módulos temporales
-- =========================================================
-- El motor (capabilities, diagnósticos, guards, registro de fichas)
-- vive en core/lsp/. Los servers siguen en servers/ hasta que las
-- fichas de lua/languages/ los absorban (F2 de la spec 002).

require("plugins.lsp.java").setup()

-- PATH de Mason en el entorno Neovim
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Cargar gestión de binarios (Mason)
pcall(require, "core.mason")

-- Motor LSP
pcall(require, "core.lsp")

-- Cargar Servidores (temporal, F2 002)
local servers = {
  "web",
  "html",
  "python",
  "lua",
  "c",
  "markdown",
  "html_css",
  "sql",
}

for _, server in ipairs(servers) do
  pcall(require, "plugins.lsp.servers." .. server)
end
