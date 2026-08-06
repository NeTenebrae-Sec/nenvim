local M = {}

-- Obtiene la palabra limpia bajo el cursor
function M.get_target_word()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local char_under_cursor = line:sub(col, col)
  if not char_under_cursor:match("[%w_%-]") then
    return nil
  end

  local start_col = col
  while start_col > 1 and line:sub(start_col - 1, start_col - 1):match("[%w_%-]") do
    start_col = start_col - 1
  end

  local end_col = col
  while end_col <= #line and line:sub(end_col, end_col):match("[%w_%-]") do
    end_col = end_col + 1
  end

  if start_col >= end_col then
    return nil
  end

  local raw_word = line:sub(start_col, end_col - 1)
  return raw_word:gsub("^%-+", ""):gsub("%-+$", "")
end

-- Extrae el texto seleccionado en modo visual de una sola línea
function M.get_visual_selection()
  vim.cmd("normal! \27")

  local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

  if start_line ~= end_line then
    return nil
  end

  local line = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1]
  if not line then
    return nil
  end

  local selection = line:sub(start_col, end_col)
  return selection ~= "" and selection or nil
end

-- Solicita un término de búsqueda al usuario
function M.prompt_user_input(callback)
  vim.ui.input({ prompt = "Trident Search: " }, function(input)
    if input and input ~= "" then
      callback(input)
    end
  end)
end

return M
