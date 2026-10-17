local M = {}
local config = require("plugins.nepost.config")
local parser = require("plugins.nepost.parser")
local client = require("plugins.nepost.client")
local history = require("plugins.nepost.history")
local env = require("plugins.nepost.env")

M.state = {
  req_buf = nil,
  res_buf = nil,
  req_win = nil,
  res_win = nil,
  split_win = nil,
}

local NS_RESPONSE = vim.api.nvim_create_namespace("nepost_response")

local SEPARATOR_PATTERN = "^─+$"
local HTTP_PATTERN = "^HTTP/"
local HEADERS_TOGGLE_PATTERN = "^Headers %(%d+%)"
local HEADER_LINE_PATTERN = "^  [a-zA-Z%-]+:%s"

local function format_status_line(status)
  local label
  if status >= 200 and status < 300 then
    label = "OK"
  elseif status >= 300 and status < 400 then
    label = "Redirect"
  elseif status >= 400 and status < 500 then
    label = "Client Error"
  elseif status >= 500 then
    label = "Server Error"
  else
    label = "Unknown"
  end
  return string.format("HTTP %d %s", status, label)
end

local function highlight_response()
  if not M.state.res_buf or not vim.api.nvim_buf_is_valid(M.state.res_buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(M.state.res_buf, NS_RESPONSE, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(M.state.res_buf, 0, -1, false)
  for i, line in ipairs(lines) do
    local row = i - 1

    if line:match(HTTP_PATTERN) then
      vim.api.nvim_buf_set_extmark(M.state.res_buf, NS_RESPONSE, row, 0, {
        end_row = row,
        end_col = #line,
        hl_group = "Statement",
      })
    elseif line:match(SEPARATOR_PATTERN) then
      vim.api.nvim_buf_set_extmark(M.state.res_buf, NS_RESPONSE, row, 0, {
        end_row = row,
        end_col = #line,
        hl_group = "Comment",
      })
    elseif line:match(HEADERS_TOGGLE_PATTERN) then
      vim.api.nvim_buf_set_extmark(M.state.res_buf, NS_RESPONSE, row, 0, {
        end_row = row,
        end_col = #line,
        hl_group = "Title",
      })
    elseif line:match(HEADER_LINE_PATTERN) then
      local key = line:match("^%s*([^:]+)")
      if key then
        local key_start = line:find(key)
        vim.api.nvim_buf_set_extmark(M.state.res_buf, NS_RESPONSE, row, key_start - 1, {
          end_row = row,
          end_col = key_start - 1 + #key,
          hl_group = "Identifier",
        })
        local val_start = key_start + #key + 2
        if val_start <= #line then
          vim.api.nvim_buf_set_extmark(M.state.res_buf, NS_RESPONSE, row, val_start - 1, {
            end_row = row,
            end_col = #line,
            hl_group = "String",
          })
        end
      end
    end
  end
end

local function toggle_headers()
  if not M.state.res_buf or not vim.api.nvim_buf_is_valid(M.state.res_buf) then
    return
  end

  local headers = vim.b[M.state.res_buf].nepost_headers or {}
  if vim.tbl_isempty(headers) then
    return
  end

  local expanded = vim.b[M.state.res_buf].nepost_headers_expanded
  local all_lines = vim.api.nvim_buf_get_lines(M.state.res_buf, 0, -1, false)

  -- Find the Headers line index
  local headers_idx = nil
  for i, line in ipairs(all_lines) do
    if line:match(HEADERS_TOGGLE_PATTERN) then
      headers_idx = i
      break
    end
  end

  if not headers_idx then
    return
  end

  if expanded then
    -- Collapse: keep everything up to and including the Headers line, discard the rest
    local new_lines = {}
    for i = 1, headers_idx do
      local line = all_lines[i]
      if i == headers_idx then
        -- Restore the ↓ arrow
        table.insert(new_lines, line:gsub("▼", "↓"))
      else
        table.insert(new_lines, line)
      end
    end
    vim.bo[M.state.res_buf].modifiable = true
    vim.api.nvim_buf_set_lines(M.state.res_buf, 0, -1, false, new_lines)
    vim.bo[M.state.res_buf].modifiable = false
    vim.b[M.state.res_buf].nepost_headers_expanded = false
  else
    -- Expand: keep everything up to Headers line, then insert header lines
    local new_lines = {}
    for i = 1, headers_idx do
      local line = all_lines[i]
      if i == headers_idx then
        -- Change arrow and insert headers after
        table.insert(new_lines, line:gsub("↓", "▼"))
        local sorted_keys = vim.tbl_keys(headers)
        table.sort(sorted_keys, function(a, b)
          return a:lower() < b:lower()
        end)
        for _, key in ipairs(sorted_keys) do
          table.insert(new_lines, "  " .. key .. ": " .. headers[key])
        end
      else
        table.insert(new_lines, line)
      end
    end
    vim.bo[M.state.res_buf].modifiable = true
    vim.api.nvim_buf_set_lines(M.state.res_buf, 0, -1, false, new_lines)
    vim.bo[M.state.res_buf].modifiable = false
    vim.b[M.state.res_buf].nepost_headers_expanded = true
  end

  highlight_response()
end

local function set_response(lines, status, headers)
  if not M.state.res_buf or not vim.api.nvim_buf_is_valid(M.state.res_buf) then
    return
  end

  vim.bo[M.state.res_buf].modifiable = true

  vim.schedule(function()
    if not M.state.res_buf or not vim.api.nvim_buf_is_valid(M.state.res_buf) then
      return
    end

    vim.api.nvim_buf_set_lines(M.state.res_buf, 0, -1, false, lines)
    vim.bo[M.state.res_buf].modifiable = false

    vim.bo[M.state.res_buf].filetype = "nepost_response"

    -- Store headers for toggle
    vim.b[M.state.res_buf].nepost_headers = headers or {}
    vim.b[M.state.res_buf].nepost_headers_expanded = false

    highlight_response()

    if M.state.res_win and vim.api.nvim_win_is_valid(M.state.res_win) then
      local title = format_status_line(status)
      vim.api.nvim_win_set_config(M.state.res_win, {
        title = " " .. title .. " ",
        title_pos = "center",
      })
    end
  end)
end

local function is_open()
  return M.state.req_win ~= nil
    and vim.api.nvim_win_is_valid(M.state.req_win)
    and M.state.res_win ~= nil
    and vim.api.nvim_win_is_valid(M.state.res_win)
end

local function close()
  if M.state.req_win and vim.api.nvim_win_is_valid(M.state.req_win) then
    vim.api.nvim_win_close(M.state.req_win, true)
  end
  if M.state.res_win and vim.api.nvim_win_is_valid(M.state.res_win) then
    vim.api.nvim_win_close(M.state.res_win, true)
  end
  if M.state.split_win and vim.api.nvim_win_is_valid(M.state.split_win) then
    vim.api.nvim_win_close(M.state.split_win, true)
  end
  M.state.req_buf = nil
  M.state.res_buf = nil
  M.state.req_win = nil
  M.state.res_win = nil
  M.state.split_win = nil
end

local function send_current_request()
  if not M.state.req_buf or not vim.api.nvim_buf_is_valid(M.state.req_buf) then
    return
  end

  local request = parser.get_request_at_cursor(M.state.req_buf)
  if not request then
    vim.notify("Nepost: No valid request found at cursor", vim.log.levels.WARN)
    return
  end

  request.url = env.resolve(request.url)
  for key, value in pairs(request.headers) do
    request.headers[key] = env.resolve(value)
  end
  if request.body then
    request.body = env.resolve(request.body)
  end

  set_response({ "Sending " .. request.method .. " " .. request.url .. " ..." }, 0)

  local cfg = config.get()
  client.send(request, function(response)
    if response.ok then
      local lines, status_text = client.format_response(response, {
        show_headers = cfg.response.show_headers,
        indent = cfg.response.indent,
        separator = cfg.response.separator,
        separator_width = cfg.response.separator_width,
      })
      set_response(lines, response.status, response.headers)
      history.save(request, response)
    else
      set_response({ "Error: " .. (response.error or "Unknown error") }, 0)
    end
  end, cfg)
end

local function save_to_collection()
  if not M.state.req_buf or not vim.api.nvim_buf_is_valid(M.state.req_buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(M.state.req_buf, 0, -1, false)
  local request = parser.get_request_at_cursor(M.state.req_buf)
  if not request then
    vim.notify("Nepost: No valid request to save", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Collection name: " }, function(name)
    if not name or name == "" then
      return
    end

    local dir = config.get().collections.dir
    local project_root = vim.fn.getcwd()
    local full_dir = project_root .. "/" .. dir .. "/" .. name

    if vim.fn.isdirectory(full_dir) == 0 then
      vim.fn.mkdir(full_dir, "p")
    end

    vim.ui.input({ prompt = "Request name: " }, function(req_name)
      if not req_name or req_name == "" then
        return
      end

      local entry = {
        method = request.method,
        url = request.url,
        headers = request.headers,
        body = request.body,
        flags = request.flags,
      }

      local filepath = full_dir .. "/" .. req_name .. ".json"
      local json = vim.json.encode(entry)
      vim.fn.writefile(vim.split(json, "\n"), filepath)
      vim.notify("Nepost: Saved to " .. name .. "/" .. req_name, vim.log.levels.INFO)
    end)
  end)
end

local function show_history()
  local entries = history.list()
  if #entries == 0 then
    vim.notify("Nepost: No history entries", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, entry in ipairs(entries) do
    table.insert(items, string.format("[%s] %s %s -> %d",
      entry.timestamp,
      entry.request.method,
      entry.request.url,
      entry.response.status
    ))
  end

  vim.ui.select(items, {
    prompt = "Nepost History",
  }, function(choice, idx)
    if not choice then
      return
    end
    local entry = entries[idx]
    local cfg = config.get()
    local lines, status_text = client.format_response({
      status = entry.response.status,
      headers = entry.response.headers,
      body = entry.response.body,
    }, {
      show_headers = cfg.response.show_headers,
      indent = cfg.response.indent,
      separator = cfg.response.separator,
      separator_width = cfg.response.separator_width,
    })
    set_response(lines, entry.response.status, entry.response.headers)
  end)
end

local function switch_environment()
  local envs = env.list_envs()
  vim.ui.select(envs, {
    prompt = "Switch Environment",
  }, function(choice)
    if choice then
      env.switch_env(choice)
    end
  end)
end

local function setup_keymaps(req_buf, res_buf)
  local opts = { buffer = req_buf, silent = true, nowait = true }

  vim.keymap.set("n", "<CR>", send_current_request, opts)
  vim.keymap.set("n", "<leader>nr", send_current_request, opts)
  vim.keymap.set("n", "<leader>ns", save_to_collection, opts)
  vim.keymap.set("n", "<leader>nh", show_history, opts)
  vim.keymap.set("n", "<leader>ne", switch_environment, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  local res_opts = { buffer = res_buf, silent = true, nowait = true }
  vim.keymap.set("n", "q", close, res_opts)
  vim.keymap.set("n", "<Esc>", close, res_opts)
  vim.keymap.set("n", "<CR>", toggle_headers, res_opts)
  vim.keymap.set("n", "za", toggle_headers, res_opts)
  vim.keymap.set("n", "zo", toggle_headers, res_opts)
  vim.keymap.set("n", "zc", toggle_headers, res_opts)
end

function M.open()
  if is_open() then
    vim.api.nvim_set_current_win(M.state.req_win)
    return
  end

  local cfg = config.get()
  local total_width = math.floor(vim.o.columns * cfg.ui.width)
  local total_height = math.floor(vim.o.lines * cfg.ui.height)
  local row = math.floor((vim.o.lines - total_height) / 2)
  local col = math.floor((vim.o.columns - total_width) / 2)

  local req_width = math.floor(total_width * cfg.ui.split_ratio)
  local res_width = total_width - req_width - 1

  local req_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[req_buf].buftype = "nofile"
  vim.bo[req_buf].bufhidden = "wipe"

  local res_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[res_buf].buftype = "nofile"
  vim.bo[res_buf].bufhidden = "wipe"

  vim.api.nvim_buf_set_lines(req_buf, 0, -1, false, {
    "GET https://httpbin.org/get",
    "",
    "",
  })

  vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {
    " Response will appear here",
    "",
    " Press <CR> in the request buffer to send",
  })

  vim.bo[res_buf].modifiable = false
  vim.bo[req_buf].filetype = "nepost"
  vim.bo[res_buf].filetype = "nepost"

  local req_win = vim.api.nvim_open_win(req_buf, true, {
    relative = "editor",
    width = req_width,
    height = total_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Request ",
    title_pos = "center",
  })

  local res_win = vim.api.nvim_open_win(res_buf, false, {
    relative = "editor",
    width = res_width,
    height = total_height,
    row = row,
    col = col + req_width + 1,
    style = "minimal",
    border = "rounded",
    title = " Response ",
    title_pos = "center",
  })

  vim.wo[req_win].number = true
  vim.wo[req_win].cursorline = true
  vim.wo[res_win].number = false
  vim.wo[res_win].wrap = true

  M.state.req_buf = req_buf
  M.state.res_buf = res_buf
  M.state.req_win = req_win
  M.state.res_win = res_win

  setup_keymaps(req_buf, res_buf)

  env.load()

  vim.api.nvim_set_current_win(req_win)
end

function M.toggle()
  if is_open() then
    close()
  else
    M.open()
  end
end

M.set_response = set_response

return M
