-- =========================================================
-- Motor Mason: instalación de binarios declarados por fichas
-- =========================================================
-- auto_update=false: sin checks de red en cada arranque (specs/tasks/003).
-- Updates manuales: :MasonToolsUpdate.
-- La lista ensure_installed se colecta de los campos `tools` de las
-- fichas de languages/ (schema 002), sin duplicados.

-- PATH de Mason en el entorno Neovim
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local ok_mason, mason = pcall(require, "mason")
if not ok_mason then
  -- R0: sin mason la config sigue arrancando; los binarios se instalan
  -- cuando haya plugin y red (:PackUpdate)
  vim.notify("mason.nvim no está instalado (se omiten binarios LSP)", vim.log.levels.WARN)
  return
end

mason.setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

-- Colectar tools de las fichas de lenguaje (dedupe, orden estable)
local tools = {}
do
  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    local seen = {}
    for _, ficha in ipairs(languages.all()) do
      for _, tool in ipairs(ficha.tools or {}) do
        if not seen[tool] then
          seen[tool] = true
          table.insert(tools, tool)
        end
      end
    end
  end
end

local ok_mti, mti = pcall(require, "mason-tool-installer")
if ok_mti then
  mti.setup({
    ensure_installed = tools,
    run_on_start = true,
    auto_update = false,
  })
end
