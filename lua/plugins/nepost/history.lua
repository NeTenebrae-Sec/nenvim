local M = {}
local config = require("plugins.nepost.config")

local function get_history_dir()
  local dir = config.get().history.dir
  local project_root = vim.fn.getcwd()
  local full_dir = project_root .. "/" .. dir
  if vim.fn.isdirectory(full_dir) == 0 then
    vim.fn.mkdir(full_dir, "p")
  end
  return full_dir
end

local function get_timestamp()
  return os.date("%Y%m%d_%H%M%S")
end

function M.save(request, response)
  local dir = get_history_dir()
  local timestamp = get_timestamp()
  local method = request.method:lower()
  local filename = string.format("%s_%s.json", timestamp, method)
  local filepath = dir .. "/" .. filename

  local entry = {
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    request = {
      method = request.method,
      url = request.url,
      headers = request.headers,
      body = request.body,
    },
    response = {
      status = response.status,
      headers = response.headers,
      body = response.body,
    },
  }

  local json = vim.json.encode(entry)
  local lines = vim.split(json, "\n")
  vim.fn.writefile(lines, filepath)

  M.trim_history()
end

function M.trim_history()
  local dir = get_history_dir()
  local files = vim.fn.readdir(dir)
  local max = config.get().history.max_entries

  if #files > max then
    table.sort(files)
    local to_remove = #files - max
    for i = 1, to_remove do
      vim.fn.delete(dir .. "/" .. files[i])
    end
  end
end

function M.list()
  local dir = get_history_dir()
  local files = vim.fn.readdir(dir)
  if not files or #files == 0 then
    return {}
  end

  table.sort(files, function(a, b)
    return a > b
  end)

  local entries = {}
  for _, filename in ipairs(files) do
    local filepath = dir .. "/" .. filename
    local content = table.concat(vim.fn.readfile(filepath), "\n")
    local ok, entry = pcall(vim.fn.json_decode, content)
    if ok and entry then
      entry._file = filepath
      entry._filename = filename
      table.insert(entries, entry)
    end
  end

  return entries
end

function M.get_entry(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end
  local content = table.concat(vim.fn.readfile(filepath), "\n")
  local ok, entry = pcall(vim.fn.json_decode, content)
  if ok then
    return entry
  end
  return nil
end

function M.delete(filepath)
  if vim.fn.filereadable(filepath) == 1 then
    vim.fn.delete(filepath)
  end
end

return M
