local filters = require("plugins.trident.search.filters")

local M = {}

function M.run_ripgrep(word, mode)
  local current_file_abs = filters.normalize_path(vim.api.nvim_buf_get_name(0))
  local current_ext = vim.fn.expand("%:e")

  local escaped_word = word:gsub("([%^%$%(%)%%%.%[%]%*%+\\%-%?])", "\\%1")
  local regex_pattern = string.format("(?<![\\w_-])%s(?![\\w_-])", escaped_word)

  local cmd_parts = { "rg", "--vimgrep", "-P" }

  local glob_args = filters.build_globs(mode)
  for _, arg in ipairs(glob_args) do
    table.insert(cmd_parts, arg)
  end

  table.insert(cmd_parts, "--")
  table.insert(cmd_parts, vim.fn.shellescape(regex_pattern))

  if mode == "current_file" then
    if current_file_abs == "" then
      return {}
    end
    table.insert(cmd_parts, vim.fn.shellescape(current_file_abs))
  end

  table.insert(cmd_parts, "2>/dev/null")

  local cmd = table.concat(cmd_parts, " ")
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local results = {}
  for line in handle:lines() do
    local parts = vim.split(line, ":")
    if #parts >= 4 then
      local match_file = filters.normalize_path(parts[1])
      local is_same_file = (match_file == current_file_abs)

      local include_match = true
      if mode == "exclude_file" and is_same_file then
        include_match = false
      elseif mode == "exclude_ext" then
        local match_ext = vim.fn.fnamemodify(match_file, ":e")
        if match_ext == current_ext then
          include_match = false
        end
      elseif mode == "current_file" and not is_same_file then
        include_match = false
      end

      if include_match then
        local text_content = table.concat({ select(4, unpack(parts)) }, ":")
        table.insert(results, {
          file = parts[1],
          lnum = tonumber(parts[2]),
          col = tonumber(parts[3]) - 1,
          text_trim = vim.trim(text_content),
        })
      end
    end
  end
  handle:close()
  return results
end

return M
