local M = {}

-- ----------------------------------------------------------------------------
-- DETECCIÓN DE PROYECTO (patrón java.lua: raíz → menú → ejecución en Kitty)
-- ----------------------------------------------------------------------------
local function get_project_root()
  return vim.fs.root(0, { "astro.config.mjs", "astro.config.ts", "package.json", ".git" })
end

-- ----------------------------------------------------------------------------
-- RUNNER: <leader>dr con menú de acciones del proyecto
-- ----------------------------------------------------------------------------
local actions = {
  { label = "1. Dev server (astro dev)", cmd = "npm run dev" },
  { label = "2. Preview build (astro preview)", cmd = "npm run preview" },
  { label = "3. Type check (astro check)", cmd = "npm run check" },
  { label = "4. Build (astro build)", cmd = "npm run build" },
}

function M.run()
  local root = get_project_root()
  if not root then
    vim.notify("No se detectó un proyecto Astro (astro.config.* / package.json).", vim.log.levels.WARN)
    return
  end

  vim.ui.select(actions, {
    prompt = "Astro: select execution action:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    local cmd = string.format("cd '%s' && %s; echo ''; read -p 'Presiona Enter para cerrar...'", root, choice.cmd)
    vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
  end)
end

-- ----------------------------------------------------------------------------
-- DAP: OPCIONAL EN FRONTEND (spec GLOBAL §4 R2)
-- El debug del cliente en navegador (pwa-chrome / js-debug, puerto 8125)
-- no se registra por defecto; el DAP de navegador se activa a petición.
-- El runner (<leader>dr, menú dev/preview/check/build) no depende de esto.
-- Para reactivarlo: registrar aquí dap.adapters["pwa-chrome"] (server
-- 127.0.0.1:8125, node js-debug/src/dapDebugServer.js) y la configuración
-- launch "Debug JS del cliente (dev server :4321)".
-- ----------------------------------------------------------------------------
function M.setup() end

return M
