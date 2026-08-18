-- =========================================================
-- Professional Vite Integration (Multi-project)
-- =========================================================

-- Starting port to search from
local BASE_PORT = 8181

-- Global in-memory table to track servers by project directory
_G.vite_active_servers = _G.vite_active_servers or {}

-- Find the vite binary: first try PATH, then fallback to npx (no global install needed)
local function find_vite()
  local path = vim.fn.exepath("vite")
  if path ~= "" then
    return path
  end
  -- Use npx vite as fallback - runs without global install
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

  -- Look for a .git directory going upwards from the current file
  local git_ancestor = vim.fs.find(".git", { path = current_dir, upward = true })[1]
  if git_ancestor then
    return vim.fs.dirname(git_ancestor)
  end

  -- Not a git repo, use the parent directory of the current file
  return current_dir
end

-- Internal function to start the Vite dev server
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

  -- Find a free port for this project
  local project_port = get_available_port()
  local vite_cmd = find_vite()

  -- Run vite dev pointing to the detected project root
  local cmd = string.format("%s dev --port %s --force '%s'", vite_cmd, project_port, project_root)

  local job_id = vim.fn.jobstart({ "zsh", "-c", cmd }, {
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
      for _, line in ipairs(data) do
        local cleaned = line:gsub("%s+", "")
        if cleaned ~= ""
          and not cleaned:find("can'tsettty")
          and not cleaned:find("Failedtorundependencyscan")
          and not cleaned:find("Thefollowingdependenciesareimported")
          and not cleaned:find("npmwarn")
          and not cleaned:find("npmERR")
          and not cleaned:find("npmnotice")
          and not cleaned:find("zle")
          and not cleaned:find("can'tchangeoption")
        then
          vim.schedule(function()
            vim.notify("Vite Error: " .. line, vim.log.levels.ERROR)
          end)
        end
      end
    end,

    on_exit = function()
      _G.vite_active_servers[project_root] = nil
    end,
  })

  -- Store server data for statusline and toggles
  _G.vite_active_servers[project_root] = { job_id = job_id, port = project_port }
  vim.notify(
    "Starting Vite on port " .. project_port .. " for " .. vim.fn.fnamemodify(project_root, ":t") .. "...",
    vim.log.levels.INFO
  )
end

-- Main toggle function (multi-project smart toggle)
local function toggle_vite_server()
  -- If the current buffer is not modifiable (e.g. NvimTree, Telescope),
  -- try to use the current working directory to handle stop/start without issues.
  if not vim.opt_local.modifiable:get() then
    local project_root = vim.fn.getcwd()
    if _G.vite_active_servers[project_root] then
      vim.fn.jobstop(_G.vite_active_servers[project_root].job_id)
      _G.vite_active_servers[project_root] = nil
      vim.notify("Vite Server stopped", vim.log.levels.INFO)
      return
    end
  end

  -- Detect the smart project root from the current file or working directory
  local project_root = get_intelligent_project_root()

  -- If this project already has a running server, stop it
  if _G.vite_active_servers[project_root] then
    vim.fn.jobstop(_G.vite_active_servers[project_root].job_id)
    _G.vite_active_servers[project_root] = nil
    vim.notify("Vite Server stopped for [" .. vim.fn.fnamemodify(project_root, ":t") .. "]", vim.log.levels.INFO)
    return
  end

  start_server(project_root)
end

return {
  toggle_vite_server = toggle_vite_server,
}