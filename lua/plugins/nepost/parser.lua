local M = {}

local METHODS = {
  GET = true,
  POST = true,
  PUT = true,
  DELETE = true,
  PATCH = true,
  HEAD = true,
  OPTIONS = true,
}

local HEADERS_MARKER = "^#%s*%[HEADERS%]%s*$"
local BODY_MARKER = "^#%s*%[BODY%]%s*$"
local FLAGS_MARKER = "^#%s*%[FLAGS%]%s*$"

function M.parse_request(lines)
  if #lines == 0 then
    return nil
  end

  local first = lines[1]:match("^%s*(.-)%s*$")
  local method, url = first:match("^(%u+)%s+(.-)%s*$")

  if not method or not METHODS[method] then
    return nil
  end

  local request = {
    method = method,
    url = url or "",
    headers = {},
    body = nil,
    flags = nil,
  }

  local has_markers = false
  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed:match(HEADERS_MARKER) or trimmed:match(BODY_MARKER) or trimmed:match(FLAGS_MARKER) then
      has_markers = true
      break
    end
  end

  if not has_markers then
    return M.parse_request_legacy(lines, request)
  end

  local section = "pre"
  local body_lines = {}
  local flags_lines = {}

  for i = 2, #lines do
    local line = lines[i]
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed:match(HEADERS_MARKER) then
      section = "headers"
    elseif trimmed:match(FLAGS_MARKER) then
      section = "flags"
    elseif trimmed:match(BODY_MARKER) then
      section = "body"
    elseif section == "headers" then
      if trimmed ~= "" then
        local key, value = trimmed:match("^([^:]+):%s*(.*)")
        if key then
          request.headers[key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
        end
      end
    elseif section == "flags" then
      if trimmed ~= "" then
        table.insert(flags_lines, trimmed)
      end
    elseif section == "body" then
      table.insert(body_lines, line)
    end
  end

  if #body_lines > 0 then
    request.body = table.concat(body_lines, "\n")
  end

  if #flags_lines > 0 then
    request.flags = table.concat(flags_lines, " ")
  end

  return request
end

function M.parse_request_legacy(lines, request)
  local i = 2
  while i <= #lines do
    local line = lines[i]:match("^%s*(.-)%s*$")
    if line == "" then
      i = i + 1
      break
    end
    local key, value = line:match("^([^:]+):%s*(.*)")
    if key then
      request.headers[key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
    end
    i = i + 1
  end

  local body_lines = {}
  while i <= #lines do
    table.insert(body_lines, lines[i])
    i = i + 1
  end

  if #body_lines > 0 then
    request.body = table.concat(body_lines, "\n")
  end

  return request
end

function M.parse_buffer(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return M.parse_requests(lines)
end

function M.parse_requests(lines)
  local requests = {}
  local current = {}

  for _, line in ipairs(lines) do
    if line:match("^###") then
      if #current > 0 then
        local req = M.parse_request(current)
        if req then
          table.insert(requests, req)
        end
        current = {}
      end
    else
      table.insert(current, line)
    end
  end

  if #current > 0 then
    local req = M.parse_request(current)
    if req then
      table.insert(requests, req)
    end
  end

  return requests
end

function M.get_request_at_cursor(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]

  local current = {}
  local start_line = 1

  for i, line in ipairs(lines) do
    if line:match("^###") then
      if cursor_line >= start_line and cursor_line < i then
        return M.parse_request(current), start_line, i - 1
      end
      current = {}
      start_line = i + 1
    else
      table.insert(current, line)
    end
  end

  if cursor_line >= start_line then
    return M.parse_request(current), start_line, #lines
  end

  return nil
end

function M.get_section_at_cursor(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  local last_section = "pre"
  local section_start = 1

  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed:match(HEADERS_MARKER) then
      if cursor_line >= section_start and cursor_line < i then
        return last_section
      end
      last_section = "headers"
      section_start = i + 1
    elseif trimmed:match(FLAGS_MARKER) then
      if cursor_line >= section_start and cursor_line < i then
        return last_section
      end
      last_section = "flags"
      section_start = i + 1
    elseif trimmed:match(BODY_MARKER) then
      if cursor_line >= section_start and cursor_line < i then
        return last_section
      end
      last_section = "body"
      section_start = i + 1
    end
  end

  if cursor_line >= section_start then
    return last_section
  end

  return "pre"
end

return M
