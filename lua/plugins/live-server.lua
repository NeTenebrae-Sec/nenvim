-- =========================================================
-- Integración Profesional con Vite Global (Multi-proyecto)
-- =========================================================

-- Puerto inicial desde el cual empezará a buscar libres
local BASE_PORT = 8181

-- Tabla global en memoria para rastrear los servidores por directorio de proyecto
_G.vite_active_servers = _G.vite_active_servers or {}

local home = os.getenv("HOME")
local vite_bin = home .. "/.local/share/pnpm/bin/vite"

-- Función para verificar si un puerto está en uso (Linux nativo)
local function is_port_free(port)
  local cmd = string.format("ss -tlnp | grep ':%d '", port)
  local handle = io.popen(cmd)

  -- Validamos que el handle no sea nil
  if not handle then
    return true -- O false, según prefieras manejar el fallo del comando
  end

  local result = handle:read("*a")
  handle:close()

  return result == ""
end
-- Función para encontrar el siguiente puerto disponible
local function get_available_port()
  local port = BASE_PORT
  while not is_port_free(port) do
    port = port + 1
  end
  return tostring(port)
end

-- Función para obtener la raíz del proyecto actual de forma inteligente
local function get_intelligent_project_root()
  local current_file = vim.api.nvim_buf_get_name(0)

  -- Si no hay archivo abierto, usamos el directorio de trabajo de Neovim
  if current_file == "" then
    return vim.fn.getcwd()
  end

  local current_dir = vim.fs.dirname(current_file)

  -- Intentamos buscar un directorio .git hacia arriba partiendo de este archivo
  local git_ancestor = vim.fs.find(".git", { path = current_dir, upward = true })[1]
  if git_ancestor then
    return vim.fs.dirname(git_ancestor)
  end

  -- Si no es un repo Git, la raíz del proyecto será la carpeta que contiene al archivo actual
  return current_dir
end

-- Función interna para arrancar el servidor de Vite
local function start_server(project_root)
  local file_path = vim.api.nvim_buf_get_name(0)
  local file_ext = vim.fn.expand("%:e")

  -- Calculamos la ruta relativa de forma limpia con normalize y gsub
  local target_page = ""
  if file_path ~= "" and file_ext == "html" then
    local norm_file = vim.fs.normalize(file_path)
    local norm_root = vim.fs.normalize(project_root)

    -- Escapamos caracteres mágicos en la ruta raíz para el patrón de búsqueda
    local pattern = "^" .. norm_root:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "/?"
    local relative_path = norm_file:gsub(pattern, "")

    if relative_path ~= "" then
      target_page = "/" .. relative_path
    end
  end

  -- Calculamos dinámicamente un puerto libre para este proyecto
  local project_port = get_available_port()

  -- Ejecutamos Vite dev apuntando explícitamente a la raíz del proyecto detectado
  local vite_cmd = string.format("%s dev --port %s --force '%s'", vite_bin, project_port, project_root)

  local job_id = vim.fn.jobstart({ "zsh", "-i", "-c", vite_cmd }, {
    on_stdout = function(_, data)
      if not data then
        return
      end
      local output = table.concat(data, "\n")

      if output:find("Local:") or output:find("http://localhost:" .. project_port) then
        vim.schedule(function()
          local full_url = "http://localhost:" .. project_port .. target_page
          vim.notify(
            "Vite [" .. vim.fn.fnamemodify(project_root, ":t") .. "] ready at " .. full_url,
            vim.log.levels.INFO
          )
          vim.fn.system("xdg-open " .. full_url .. " &")
        end)
      end
    end,

    on_stderr = function(_, data)
      if not data then
        return
      end
      local err = table.concat(data, "\n"):gsub("%s+", "")
      -- Filtramos falsos positivos y logs ruidosos comunes de dependencias huérfanas
      if
        err ~= ""
        and not err:find("can'tsettty")
        and not err:find("Failedtorundependencyscan")
        and not err:find("Thefollowingdependenciesareimported")
      then
        vim.schedule(function()
          vim.notify("Vite Error: " .. err, vim.log.levels.ERROR)
        end)
      end
    end,

    on_exit = function()
      _G.vite_active_servers[project_root] = nil
    end,
  })

  -- Guardamos la estructura de datos para Lualine y Toggles vinculada a este proyecto
  _G.vite_active_servers[project_root] = { job_id = job_id, port = project_port }
  vim.notify(
    "Starting Vite on port " .. project_port .. " for " .. vim.fn.fnamemodify(project_root, ":t") .. "...",
    vim.log.levels.INFO
  )
end

-- Función principal (Toggle inteligente multi-proyecto)
local function toggle_vite_server()
  -- Si el buffer actual no es modificable (por ejemplo, NvimTree, Telescope, etc.),
  -- nos aseguramos de no intentar ejecutar acciones del buffer si no es necesario.
  if not vim.opt_local.modifiable:get() then
    -- Si es un buffer especial inútil, intentamos usar el directorio actual de Neovim
    -- para no interrumpir el proceso de apagado/encendido de servidores.
    local project_root = vim.fn.getcwd()
    if _G.vite_active_servers[project_root] then
      vim.fn.jobstop(_G.vite_active_servers[project_root].job_id)
      _G.vite_active_servers[project_root] = nil
      vim.notify("Vite Server stopped", vim.log.levels.INFO)
      return
    end
  end

  -- Detectamos la raíz inteligente basada en tu archivo actual o proyecto
  local project_root = get_intelligent_project_root()

  -- SI ESTE PROYECTO YA TIENE UN SERVIDOR: Lo detenemos de forma aislada
  if _G.vite_active_servers[project_root] then
    vim.fn.jobstop(_G.vite_active_servers[project_root].job_id)
    _G.vite_active_servers[project_root] = nil
    vim.notify("Vite Server stopped for [" .. vim.fn.fnamemodify(project_root, ":t") .. "]", vim.log.levels.INFO)
    return
  end

  -- AUTO-INSTALACIÓN
  if vim.fn.executable(vite_bin) ~= 1 then
    vim.notify("Vite not found. Installing globally...", vim.log.levels.WARN)
    vim.fn.jobstart({ "zsh", "-i", "-c", "pnpm add -g vite" }, {
      on_exit = function(_, exit_code)
        if exit_code == 0 and vim.fn.executable(vite_bin) == 1 then
          vim.schedule(function()
            vim.notify("Vite installed successfully!", vim.log.levels.INFO)
            start_server(project_root)
          end)
        else
          vim.schedule(function()
            vim.notify("Global installation failed.", vim.log.levels.ERROR)
          end)
        end
      end,
    })
    return
  end

  start_server(project_root)
end

return {
  toggle_vite_server = toggle_vite_server,
}
