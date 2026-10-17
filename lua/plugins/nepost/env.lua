local M = {}
local config = require("plugins.nepost.config")

M.current_env = nil
M.envs = {}

local function get_env_path()
  local project_root = vim.fn.getcwd()
  return project_root .. "/" .. config.get().env.file
end

function M.load()
  local path = get_env_path()
  if vim.fn.filereadable(path) == 0 then
    M.envs = { default = {} }
    M.current_env = "default"
    return
  end

  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok, data = pcall(vim.fn.json_decode, content)
  if ok and data then
    M.envs = data
    M.current_env = M.current_env or config.get().env.default
    if not M.envs[M.current_env] then
      M.current_env = next(M.envs)
    end
  else
    M.envs = { default = {} }
    M.current_env = "default"
  end
end

function M.save()
  local path = get_env_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  local json = vim.json.encode(M.envs)
  local lines = vim.split(json, "\n")
  vim.fn.writefile(lines, path)
end

function M.resolve(text)
  if not text or text == "" then
    return text
  end

  local vars = M.envs[M.current_env] or {}
  return text:gsub("{{([^}]+)}}", function(var_name)
    return vars[var_name] or "{{" .. var_name .. "}}"
  end)
end

function M.set_var(key, value)
  if not M.envs[M.current_env] then
    M.envs[M.current_env] = {}
  end
  M.envs[M.current_env][key] = value
  M.save()
end

function M.get_vars()
  return M.envs[M.current_env] or {}
end

function M.switch_env(env_name)
  if M.envs[env_name] then
    M.current_env = env_name
    vim.notify("Nepost: Switched to environment '" .. env_name .. "'", vim.log.levels.INFO)
  else
    vim.notify("Nepost: Environment '" .. env_name .. "' not found", vim.log.levels.WARN)
  end
end

function M.list_envs()
  return vim.tbl_keys(M.envs)
end

function M.create_env(env_name)
  if M.envs[env_name] then
    vim.notify("Nepost: Environment '" .. env_name .. "' already exists", vim.log.levels.WARN)
    return
  end
  M.envs[env_name] = {}
  M.save()
  vim.notify("Nepost: Created environment '" .. env_name .. "'", vim.log.levels.INFO)
end

return M
