local M = {}
local config = require("plugins.nepost.config")

local function get_collections_dir()
  local dir = config.get().collections.dir
  local project_root = vim.fn.getcwd()
  return project_root .. "/" .. dir
end

function M.list_collections()
  local dir = get_collections_dir()
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end

  local collections = {}
  local entries = vim.fn.readdir(dir)
  for _, entry in ipairs(entries) do
    local entry_path = dir .. "/" .. entry
    if vim.fn.isdirectory(entry_path) == 1 then
      local files = vim.fn.readdir(entry_path)
      local http_files = vim.tbl_filter(function(f)
        return f:match("%.json$")
      end, files)
      table.insert(collections, {
        name = entry,
        count = #http_files,
        path = entry_path,
      })
    end
  end

  return collections
end

function M.list_requests(collection_name)
  local dir = get_collections_dir() .. "/" .. collection_name
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end

  local requests = {}
  local files = vim.fn.readdir(dir)
  for _, filename in ipairs(files) do
    if filename:match("%.json$") then
      local filepath = dir .. "/" .. filename
      local content = table.concat(vim.fn.readfile(filepath), "\n")
      local ok, entry = pcall(vim.fn.json_decode, content)
      if ok and entry then
        entry._file = filepath
        entry._name = filename:match("(.+)%.json$")
        table.insert(requests, entry)
      end
    end
  end

  return requests
end

function M.delete_request(collection_name, request_name)
  local dir = get_collections_dir() .. "/" .. collection_name
  local filepath = dir .. "/" .. request_name .. ".json"
  if vim.fn.filereadable(filepath) == 1 then
    vim.fn.delete(filepath)
    if #vim.fn.readdir(dir) == 0 then
      vim.fn.delete(dir, "rf")
    end
    return true
  end
  return false
end

function M.open_picker()
  local collections = M.list_collections()
  if #collections == 0 then
    vim.notify("Nepost: No collections found", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, col in ipairs(collections) do
    table.insert(items, string.format("%s (%d requests)", col.name, col.count))
  end

  vim.ui.select(items, {
    prompt = "Collections",
  }, function(choice, idx)
    if not choice then
      return
    end

    local col = collections[idx]
    local requests = M.list_requests(col.name)
    if #requests == 0 then
      vim.notify("Nepost: Collection is empty", vim.log.levels.INFO)
      return
    end

    local req_items = {}
    for _, req in ipairs(requests) do
      table.insert(req_items, string.format("[%s] %s", req.method, req.url))
    end

    vim.ui.select(req_items, {
      prompt = col.name .. " requests",
    }, function(req_choice, req_idx)
      if not req_choice then
        return
      end

      local req = requests[req_idx]
      local lines = {
        req.method .. " " .. req.url,
      }
      if req.headers then
        for key, value in pairs(req.headers) do
          table.insert(lines, key .. ": " .. value)
        end
      end
      table.insert(lines, "")
      if req.body then
        for line in req.body:gmatch("[^\n]+") do
          table.insert(lines, line)
        end
      end

      local ui = require("plugins.nepost.ui")
      if not (ui.state.req_win and vim.api.nvim_win_is_valid(ui.state.req_win)) then
        ui.open()
      end

      vim.api.nvim_buf_set_lines(ui.state.req_buf, 0, -1, false, lines)
      vim.api.nvim_set_current_win(ui.state.req_win)
    end)
  end)
end

return M
