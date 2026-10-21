-- =========================================================
-- :checkhealth nete — estado de nenvim por lenguaje
-- =========================================================
-- Tabla por ficha: binarios (PATH/tools), parsers treesitter y
-- servers LSP. Defensivo (R0): todo con pcall; sin plugins la
-- respuesta es "ausente", nunca un error.

local M = {}

--- Estado de un tool: "path" | "tools-bin" | "tools-pkg" | nil
local function tool_state(tool)
  if vim.fn.executable(tool) == 1 then
    return "path"
  end
  local tools = vim.fn.stdpath("data") .. "/tools/"
  local ok_reg, registry = pcall(require, "core.tools.registry")
  local recipe = ok_reg and registry.recipes[tool] or nil
  -- Exposed bins are the names the config actually resolves
  for _, bin in ipairs(recipe and recipe.bins or { tool }) do
    if vim.fn.executable(tools .. "bin/" .. bin) == 1 then
      return "tools-bin"
    end
  end
  -- Package installed but no exposed bin (jar-only tools)
  if vim.uv.fs_stat(tools .. "packages/" .. tool) then
    return "tools-pkg"
  end
  return nil
end

function M.check()
  -- 1. Motores (plugins de infraestructura)
  vim.health.start("nenvim: motores")
  local engines = {
    { "conform", "formato" },
    { "lint", "lint" },
    { "dap", "depuración" },
    { "cmp", "completado" },
    { "nvim-treesitter", "parsers" },
  }
  for _, e in ipairs(engines) do
    local ok = pcall(require, e[1])
    if ok then
      vim.health.ok(e[2] .. ": plugin presente")
    else
      vim.health.warn(e[2] .. ": plugin ausente (instalar con :PackUpdate)")
    end
  end

  -- 2. Scanner y fichas
  local ok, languages = pcall(require, "languages")
  if not ok or not languages then
    vim.health.error("scanner languages/ no carga")
    return
  end

  local fichas = languages.all()
  vim.health.start("nenvim: fichas de lenguaje (" .. #fichas .. ")")

  for _, ficha in ipairs(fichas) do
    local problems = {}

    -- Binarios declarados (tools)
    local missing_tools = {}
    for _, tool in ipairs(ficha.tools or {}) do
      if not tool_state(tool) then
        table.insert(missing_tools, tool)
      end
    end
    if #missing_tools > 0 then
      table.insert(problems, "tools ausentes: " .. table.concat(missing_tools, ", "))
    end

    -- Servers LSP (cmd ejecutable)
    local missing_cmds = {}
    for _, server in ipairs(ficha.lsp or {}) do
      if type(server) == "table" and server.config and server.config.cmd and server.config.cmd[1] then
        local bin = server.config.cmd[1]
        if not tool_state(bin) then
          table.insert(missing_cmds, server.name .. " (" .. bin .. ")")
        end
      end
    end
    if #missing_cmds > 0 then
      table.insert(problems, "LSP sin binario: " .. table.concat(missing_cmds, ", "))
    end

    -- Parsers treesitter
    local missing_parsers = {}
    for _, parser in ipairs(ficha.parsers or {}) do
      if not pcall(vim.treesitter.language.add, parser) then
        table.insert(missing_parsers, parser)
      end
    end
    if #missing_parsers > 0 then
      table.insert(problems, "parsers ausentes: " .. table.concat(missing_parsers, ", "))
    end

    if #problems == 0 then
      vim.health.ok(ficha.name .. ": completo")
    else
      vim.health.warn(ficha.name .. ": " .. table.concat(problems, " | "), {
        "binarios: :ToolsInstall <lang> · parsers: :TSUpdate",
      })
    end
  end
end

return M
