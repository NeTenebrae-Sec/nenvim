-- =========================================================
-- Web server multi-proyecto (<leader>us): vite o astro dev
-- =========================================================

-- Local directory to install vite (avoids needing global install or internet)
local VITE_DIR = vim.fn.stdpath("data") .. "/vite-server"

-- Starting port to search from
local BASE_PORT = 8181

-- Global in-memory table to track servers by project directory
_G.vite_active_servers = _G.vite_active_servers or {}

-- Find the vite binary: PATH → local dir → auto-install → npx fallback
local function find_vite()
  -- 1. Check if vite is in PATH (global install)
  local path = vim.fn.exepath("vite")
  if path ~= "" then
    return path
  end

  -- 2. Check local installation directory
  local local_bin = VITE_DIR .. "/node_modules/.bin/vite"
  if vim.fn.filereadable(local_bin) == 1 then
    return local_bin
  end

  -- 3. Auto-install vite locally (one-time, ~20MB)
  vim.notify("Vite not found. Installing locally to " .. VITE_DIR .. "...", vim.log.levels.INFO)
  local install_cmd = string.format("npm install --prefix '%s' vite", VITE_DIR)
  local result = vim.fn.system(install_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install Vite locally. Falling back to npx.", vim.log.levels.WARN)
    return "npx vite"
  end

  -- 4. Re-check after install
  if vim.fn.filereadable(local_bin) == 1 then
    vim.notify("Vite installed successfully!", vim.log.levels.INFO)
    return local_bin
  end

  -- 5. Last resort: npx (needs internet)
  return "npx vite"
end

-- Check if a port is in use (Linux)
local function is_port_free(port)
  local cmd = string.format("ss -tlnp | grep ':%d '", port)
  local handle = io.popen(cmd)
  if not handle then
    return true
  end
  local result = handle:read("*a")
  handle:close()
  return result == ""
end

-- Find the next available port
local function get_available_port()
  local port = BASE_PORT
  while not is_port_free(port) do
    port = port + 1
  end
  return tostring(port)
end

-- Smart detection of the current project root
local function get_intelligent_project_root()
  local current_file = vim.api.nvim_buf_get_name(0)

  if current_file == "" then
    return vim.fn.getcwd()
  end

  local current_dir = vim.fs.dirname(current_file)

  -- Marcadores de proyecto hacia arriba, en orden: configs de framework
  -- (cubre scaffolds astro/next sin git), luego package.json/.git.
  -- Mismo criterio que los root_markers de los motores LSP.
  local framework_cfgs = {
    "astro.config.mjs", "astro.config.js", "astro.config.ts", "astro.config.cjs",
    "next.config.mjs", "next.config.js", "next.config.ts", "next.config.cjs",
  }
  local found = vim.fs.find(framework_cfgs, { path = current_dir, upward = true })[1]
  if found then
    return vim.fs.dirname(found)
  end

  found = vim.fs.find({ "package.json", ".git" }, { path = current_dir, upward = true })[1]
  if found then
    return vim.fs.dirname(found)
  end

  -- Sin manifiesto (web estática): el directorio del propio archivo
  return current_dir
end

-- Astro 7: el CLI puede morir dejando un daemon vivo o quedarse como job
-- foreground — el estado es por proyecto/puerto, y el stop cubre ambos casos.
local function stop_server(project_root, server)
  local alive = server.job_id and vim.fn.jobwait({ server.job_id }, 0)[1] == -1

  if server.framework == "astro" then
    vim.fn.jobstart({ project_root .. "/node_modules/.bin/astro", "dev", "stop" }, { cwd = project_root })
    if alive then
      vim.fn.jobstop(server.job_id)
    end
  elseif alive then
    vim.fn.jobstop(server.job_id)
  end

  _G.vite_active_servers[project_root] = nil
  vim.notify("Web: servidor detenido (" .. vim.fn.fnamemodify(project_root, ":t") .. ")", vim.log.levels.INFO)
end

-- Internal function to start the dev server (vite o astro)
local function start_server(project_root)
  local file_path = vim.api.nvim_buf_get_name(0)
  local file_ext = vim.fn.expand("%:e")

  -- Calculate the relative target page cleanly
  local target_page = ""
  if file_path ~= "" and file_ext == "html" then
    local norm_file = vim.fs.normalize(file_path)
    local norm_root = vim.fs.normalize(project_root)

    -- Escape magic characters in the root path for pattern matching
    local pattern = "^" .. norm_root:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "/?"
    local relative_path = norm_file:gsub(pattern, "")

    if relative_path ~= "" then
      target_page = "/" .. relative_path
    end
  end

  -- Framework detection: astro (bin+config) → next (bin) → vite
  local astro_bin = project_root .. "/node_modules/.bin/astro"
  local next_bin = project_root .. "/node_modules/.bin/next"
  local is_astro = vim.fn.filereadable(astro_bin) == 1 and vim.fn.glob(project_root .. "/astro.config.*") ~= ""
  local is_next = not is_astro and vim.fn.filereadable(next_bin) == 1
  local framework = is_astro and "astro" or (is_next and "next" or "vite")

  -- Astro 7: sin root posicional (es el subcommand stop/status/logs) → cwd = root;
  -- sin --port: respeta su puerto por defecto/config (4321 en neteumbra).
  -- El puerto real se extrae del output, nunca del estimado.
  local cmd
  if is_astro then
    cmd = string.format("'%s' dev", astro_bin)
  elseif is_next then
    -- next dev del proyecto (puerto por defecto 3000 o el de next.config)
    cmd = string.format("'%s' dev", next_bin)
  else
    cmd = string.format("%s dev --port %s --force", find_vite(), get_available_port())
  end

  local output_buf = "" -- acumula stdout+stderr: una URL no debe partirse entre chunks
  local opened = false
  local job_id -- declarado antes: on_output compara contra él para ignorar jobs viejos

  local function on_output(_, data) -- firma jobstart: (job_id, data, event)
    if not data then
      return
    end
    output_buf = output_buf .. table.concat(data, "\n") .. "\n"

    local entry = _G.vite_active_servers[project_root]
    if opened or not entry or entry.job_id ~= job_id then
      return
    end

    -- Cubre los 3 mensajes de astro (arranque, "already running", throw con URL) y vite "Local:"
    local port = output_buf:match("http://localhost:(%d+)")
    if not port then
      return
    end

    opened = true
    entry.port = port
    vim.schedule(function()
      vim.fn.system("xdg-open 'http://localhost:" .. port .. target_page .. "' &")
      vim.notify("Web: sirviendo en http://localhost:" .. port .. " (" .. framework .. ")", vim.log.levels.INFO)
    end)
  end

  job_id = vim.fn.jobstart({ "zsh", "-c", cmd }, {
    cwd = project_root,
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(_, code) -- firma jobstart: (job_id, exit_code, event)
      local entry = _G.vite_active_servers[project_root]
      if not entry or entry.job_id ~= job_id then
        return -- stop explícito desde esta misma config, u otro start más reciente
      end
      if framework == "astro" and opened then
        return -- URL parseada = server viva (daemon propio o externo adoptado)
      end
      _G.vite_active_servers[project_root] = nil
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("Web: el server terminó con error (código " .. code .. ")", vim.log.levels.ERROR)
        end)
      end
    end,
  })

  -- Estado síncrono: el toggle y lualine lo ven antes de que llegue el output
  _G.vite_active_servers[project_root] = { job_id = job_id, framework = framework }
end

-- Main toggle function (multi-project smart toggle)
local function toggle_vite_server()
  -- Desde buffers no-editables (dashboard, terminal) el contexto es el cwd
  local project_root = vim.opt_local.modifiable:get() and get_intelligent_project_root() or vim.fn.getcwd()

  local server = _G.vite_active_servers[project_root]
  if server then
    stop_server(project_root, server)
  else
    start_server(project_root)
  end
end

return {
  toggle_vite_server = toggle_vite_server,
}
