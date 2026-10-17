local M = {}
local parser = require("plugins.nepost.parser")
local client = require("plugins.nepost.client")
local env = require("plugins.nepost.env")
local history = require("plugins.nepost.history")

local ANNOTATION_PATTERN = "^//%s*@(%u+)%s+(.-)%s*$"

function M.parse_annotation(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 5, false)

  for _, line in ipairs(lines) do
    local method, url = line:match(ANNOTATION_PATTERN)
    if method and url then
      return method, url
    end
  end

  return nil, nil
end

function M.send_from_file(buf)
  buf = buf or 0

  local method, url = M.parse_annotation(buf)

  if not method or not url then
    local methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }
    vim.ui.select(methods, { prompt = "HTTP Method" }, function(choice)
      if not choice then
        return
      end
      vim.ui.input({ prompt = "URL: " }, function(input_url)
        if not input_url or input_url == "" then
          return
        end
        M._execute(buf, choice, input_url)
      end)
    end)
    return
  end

  M._execute(buf, method, url)
end

function M._execute(buf, method, url)
  url = env.resolve(url)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local body_lines = {}
  for _, line in ipairs(lines) do
    if not line:match("^//") then
      table.insert(body_lines, line)
    end
  end

  local body = table.concat(body_lines, "\n"):match("^%s*(.-)%s*$")

  local request = {
    method = method,
    url = url,
    headers = {
      ["Content-Type"] = "application/json",
      ["Accept"] = "application/json",
    },
    body = body,
  }

  local ui = require("plugins.nepost.ui")
  if not (ui.state.req_win and vim.api.nvim_win_is_valid(ui.state.req_win)) then
    ui.open()
  end

  vim.bo[ui.state.req_buf].modifiable = true
  local req_lines = { method .. " " .. url, "Content-Type: application/json", "Accept: application/json", "" }
  for _, line in ipairs(body_lines) do
    table.insert(req_lines, line)
  end
  vim.api.nvim_buf_set_lines(ui.state.req_buf, 0, -1, false, req_lines)
  vim.bo[ui.state.req_buf].modifiable = false

  vim.bo[ui.state.res_buf].modifiable = true
  vim.bo[ui.state.res_buf].filetype = "json"
  pcall(vim.treesitter.start, ui.state.res_buf, "json")
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(ui.state.res_buf) then
      vim.api.nvim_buf_set_lines(ui.state.res_buf, 0, -1, false, {
        " Sending " .. method .. " " .. url .. " ...",
      })
      vim.bo[ui.state.res_buf].modifiable = false
    end
  end)

  client.send(request, function(response)
    if response.ok then
      local res_lines, _ = client.format_response(response)
      vim.bo[ui.state.res_buf].modifiable = true
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ui.state.res_buf) then
          vim.api.nvim_buf_set_lines(ui.state.res_buf, 0, -1, false, res_lines)
          vim.bo[ui.state.res_buf].modifiable = false
        end
      end)
      history.save(request, response)
    else
      vim.bo[ui.state.res_buf].modifiable = true
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ui.state.res_buf) then
          vim.api.nvim_buf_set_lines(ui.state.res_buf, 0, -1, false, {
            "Error: " .. (response.error or "Unknown error"),
          })
          vim.bo[ui.state.res_buf].modifiable = false
        end
      end)
    end
  end)
end

return M
