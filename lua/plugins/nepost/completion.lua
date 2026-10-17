local M = {}
local config = require("plugins.nepost.config")
local env = require("plugins.nepost.env")
local parser = require("plugins.nepost.parser")

local HEADERS_MARKER = "^#%s*%[HEADERS%]%s*$"
local BODY_MARKER = "^#%s*%[BODY%]%s*$"

local function get_cursor_line_and_col()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return cursor[1], cursor[2]
end

local function get_line_text(buf, lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)
  return lines and lines[1] or ""
end

local function find_current_section(buf, cursor_line)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local section = "pre"

  for i = 1, cursor_line do
    local trimmed = lines[i]:match("^%s*(.-)%s*$")
    if trimmed:match(HEADERS_MARKER) then
      section = "headers"
    elseif trimmed:match(BODY_MARKER) then
      section = "body"
    end
  end

  return section
end

local function get_line_context(buf, cursor_line, cursor_col)
  local line = get_line_text(buf, cursor_line)
  local before = line:sub(1, cursor_col)
  local section = find_current_section(buf, cursor_line)

  if section == "pre" then
    local method = before:match("^(%u*)$")
    if method then
      return "method", method
    end
    local url_part = before:match("^%u+%s+(.-)$")
    if url_part and not before:match(":") then
      return "url", url_part
    end
  end

  if section == "headers" then
    local header_key = before:match("^([%w%-]+)$")
    if header_key then
      return "header_key", header_key
    end

    local header_value = before:match("^([%w%-]+):%s*(.-)$")
    if header_value then
      local key = header_value:match("^([%w%-]+)")
      if key == "Content-Type" or key == "Accept" then
        return "content_type", header_value:match(":%s*(.*)$")
      end
      return "header_value", header_value
    end
  end

  if section == "body" then
    local word = before:match("([%w_]+)$")
    if word then
      return "body_snippet", word
    end
  end

  return "unknown", before
end

function M.omnifunc(findstart, base)
  local buf = vim.api.nvim_get_current_buf()

  if findstart == 1 then
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, cursor_col)

    local section = find_current_section(buf, vim.api.nvim_win_get_cursor(0)[1])

    if section == "body" then
      local word_start = before:find("([%w_]+)$")
      return word_start and (word_start - 1) or cursor_col
    end

    local start = before:find("[^%s]*$")
    return start and (start - 1) or 0
  end

  local cursor_line, cursor_col = get_cursor_line_and_col()
  local ctx, partial = get_line_context(buf, cursor_line, cursor_col)
  local candidates = {}

  if ctx == "method" then
    for _, m in ipairs(config.get().methods) do
      if m:lower():find(partial:lower(), 1, true) then
        table.insert(candidates, m)
      end
    end
  elseif ctx == "header_key" then
    for _, h in ipairs(config.get().headers) do
      if h:lower():find(partial:lower(), 1, true) then
        table.insert(candidates, h)
      end
    end
    local vars = env.get_vars()
    for key, _ in pairs(vars) do
      local var = "{{" .. key .. "}}"
      if var:lower():find(partial:lower(), 1, true) then
        table.insert(candidates, var)
      end
    end
  elseif ctx == "content_type" then
    for _, ct in ipairs(config.get().content_types) do
      if ct:lower():find(partial:lower(), 1, true) then
        table.insert(candidates, ct)
      end
    end
  elseif ctx == "url" then
    local vars = env.get_vars()
    for key, _ in pairs(vars) do
      local var = "{{" .. key .. "}}"
      if var:lower():find(partial:lower(), 1, true) then
        table.insert(candidates, var)
      end
    end
  elseif ctx == "body_snippet" then
    local snippets = config.get().snippets
    for trigger, expansion in pairs(snippets) do
      if trigger:find(partial:lower(), 1, true) then
        table.insert(candidates, trigger)
      end
    end
  end

  return candidates
end

function M.insert_snippet(trigger)
  local snippets = config.get().snippets
  local expansion = snippets[trigger]
  if not expansion then
    return false
  end

  local buf = vim.api.nvim_get_current_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local line = get_line_text(buf, cursor_line)

  local before = line:match("^(.-)" .. trigger:gsub("(%W)", "%%%1") .. "$")
  local after = line:sub(#before + #trigger + 1)

  local snippet_lines = vim.split(expansion, "\n", { plain = true })

  local new_lines = {}
  if before ~= "" then
    table.insert(new_lines, before .. snippet_lines[1])
  else
    table.insert(new_lines, snippet_lines[1])
  end

  for i = 2, #snippet_lines do
    table.insert(new_lines, snippet_lines[i])
  end

  if after ~= "" then
    new_lines[#new_lines] = new_lines[#new_lines] .. after
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, cursor_line - 1, cursor_line, false, new_lines)

  local target_line = cursor_line + #snippet_lines - 1
  local target_col = #new_lines[#new_lines]
  pcall(vim.api.nvim_win_set_cursor, 0, { target_line, target_col })

  return true
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "nepost",
    callback = function(ev)
      vim.bo[ev.buf].omnifunc = "v:lua.require'plugins.nepost.completion'.omnifunc"
      vim.keymap.set("i", "<C-x><C-o>", "<C-x><C-o>", { buffer = ev.buf, silent = true })

      vim.keymap.set("i", "<Tab>", function()
        local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
        local section = find_current_section(ev.buf, cursor_line)

        if section == "body" then
          local line = get_line_text(ev.buf, cursor_line)
          local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(1, cursor_col)
          local word = before:match("([%w_]+)$")

          if word then
            for trigger, _ in pairs(config.get().snippets) do
              if trigger == word then
                M.insert_snippet(trigger)
                return
              end
            end
          end
        end

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
      end, { buffer = ev.buf, silent = true })
    end,
  })
end

return M
