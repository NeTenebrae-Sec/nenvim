local M = {}

local function pretty_print_json(obj, indent, current_indent)
  indent = indent or 2
  current_indent = current_indent or 0
  local padding = string.rep(" ", current_indent)
  local inner_padding = string.rep(" ", current_indent + indent)

  if type(obj) == "table" then
    local is_array = #obj > 0 or next(obj) == nil
    if is_array then
      if #obj == 0 then
        return "[]"
      end
      local parts = {}
      for _, v in ipairs(obj) do
        table.insert(parts, inner_padding .. pretty_print_json(v, indent, current_indent + indent))
      end
      return "[\n" .. table.concat(parts, ",\n") .. "\n" .. padding .. "]"
    else
      local keys = vim.tbl_keys(obj)
      table.sort(keys)
      if #keys == 0 then
        return "{}"
      end
      local parts = {}
      for _, k in ipairs(keys) do
        local v = pretty_print_json(obj[k], indent, current_indent + indent)
        local key = '"' .. k:gsub('"', '\\"') .. '"'
        table.insert(parts, inner_padding .. key .. ": " .. v)
      end
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. padding .. "}"
    end
  elseif type(obj) == "string" then
    return '"' .. obj:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
  elseif type(obj) == "boolean" then
    return tostring(obj)
  elseif type(obj) == "number" then
    return tostring(obj)
  elseif obj == nil then
    return "null"
  end
  return tostring(obj)
end

function M.pretty_print(str, indent)
  indent = indent or 2
  local ok, decoded = pcall(vim.fn.json_decode, str)
  if ok and decoded then
    return pretty_print_json(decoded, indent)
  end
  return str
end

function M.build_curl_args(request, config)
  local args = { "curl", "-s", "-S", "-i" }

  -- Merge flags: config defaults + request flags
  local default_flags = (config and config.curl and config.curl.default_flags) or {}
  for _, flag in ipairs(default_flags) do
    table.insert(args, flag)
  end

  if request.flags and request.flags ~= "" then
    for flag in request.flags:gmatch("%S+") do
      table.insert(args, flag)
    end
  end

  table.insert(args, "-X")
  table.insert(args, request.method)

  for key, value in pairs(request.headers) do
    table.insert(args, "-H")
    table.insert(args, key .. ": " .. value)
  end

  if request.body and request.body ~= "" then
    table.insert(args, "-d")
    table.insert(args, request.body)
  end

  table.insert(args, "-w")
  table.insert(args, "\n---NEPOST_STATUS:%{http_code}---\n")

  table.insert(args, request.url)

  return args
end

function M.format_curl_command(request, config)
  local parts = { "curl", "-s", "-S", "-i" }

  -- Merge flags
  local default_flags = (config and config.curl and config.curl.default_flags) or {}
  for _, flag in ipairs(default_flags) do
    table.insert(parts, flag)
  end

  if request.flags and request.flags ~= "" then
    for flag in request.flags:gmatch("%S+") do
      table.insert(parts, flag)
    end
  end

  table.insert(parts, "-X")
  table.insert(parts, request.method)

  for key, value in pairs(request.headers) do
    table.insert(parts, "-H")
    table.insert(parts, string.format('"%s: %s"', key, value))
  end

  if request.body and request.body ~= "" then
    table.insert(parts, "-d")
    table.insert(parts, string.format("'%s'", request.body))
  end

  table.insert(parts, string.format('"%s"', request.url))

  local cmd = table.concat(parts, " ")
  if #cmd > 80 then
    local result = {}
    local current = ""
    for _, part in ipairs(parts) do
      if #current + #part + 1 > 76 then
        table.insert(result, current .. " \\")
        current = "  " .. part
      else
        if current == "" then
          current = part
        else
          current = current .. " " .. part
        end
      end
    end
    if current ~= "" then
      table.insert(result, current)
    end
    return table.concat(result, "\n")
  end

  return cmd
end

function M.send(request, callback, config)
  local args = M.build_curl_args(request, config)
  local curl_cmd = M.format_curl_command(request, config)

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback({
          ok = false,
          error = result.stderr or "curl failed with code " .. result.code,
          status = 0,
          curl_cmd = curl_cmd,
        })
        return
      end

      local stdout = result.stdout or ""

      local status = stdout:match("---NEPOST_STATUS:(%d+)%-%-%-%s*$")
      if not status then
        callback({
          ok = false,
          error = "Failed to parse curl response",
          status = 0,
          curl_cmd = curl_cmd,
        })
        return
      end

      local http_content = stdout:match("^(.-)---NEPOST_STATUS:")
      if not http_content then
        callback({
          ok = false,
          error = "Failed to extract HTTP response",
          status = 0,
          curl_cmd = curl_cmd,
        })
        return
      end

      local headers = {}
      local body = http_content

      local sep_pos = http_content:find("\r?\n\r?\n")
      if sep_pos then
        local header_section = http_content:sub(1, sep_pos - 1)
        body = http_content:sub(sep_pos + 1)

        for line in header_section:gmatch("[^\r\n]+") do
          local key, value = line:match("^([^:]+):%s*(.*)")
          if key then
            headers[key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
          end
        end
      end

      callback({
        ok = tonumber(status) >= 200 and tonumber(status) < 400,
        status = tonumber(status),
        headers = headers,
        body = body,
        curl_cmd = curl_cmd,
      })
    end)
  end)
end

function M.format_status(status)
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

function M.format_response(response, opts)
  opts = opts or {}
  local indent = opts.indent or 2
  local separator = opts.separator or "─"
  local separator_width = opts.separator_width or 50

  local lines = {}

  -- Headers at the top (collapsible)
  if response.headers then
    local count = vim.tbl_count(response.headers)
    table.insert(lines, string.format("Headers (%d) ↓", count))
  end

  -- Separator
  table.insert(lines, string.rep(separator, separator_width))

  -- Status line
  local status_text = M.format_status(response.status)
  table.insert(lines, status_text)

  -- Separator
  table.insert(lines, string.rep(separator, separator_width))

  -- Body (JSON formatted)
  if response.body then
    local trimmed = response.body:match("^%s*(.-)%s*$")
    if trimmed ~= "" then
      local pretty = M.pretty_print(trimmed, indent)
      for line in pretty:gmatch("[^\n]+") do
        table.insert(lines, line)
      end
    end
  end

  -- Separator
  table.insert(lines, string.rep(separator, separator_width))

  return lines, status_text
end

return M
