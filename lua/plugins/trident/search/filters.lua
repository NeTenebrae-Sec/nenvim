local M = {}

M.CODE_IGNORE_PATTERNS = {
  "!*.md",
  "!*.txt",
  "!*.log",
  "!*.json",
  "!*.yaml",
  "!*.yml",
  "!*.toml",
  "!*.lock",
  "!*.svg",
  "!package-lock.json",
  "!yarn.lock",
}

-- Devuelve la etiqueta de estado a mostrar en la interfaz
function M.get_mode_filter_label(mode)
  local cur_file = vim.fn.expand("%:t")
  local cur_ext = vim.fn.expand("%:e")

  if mode == "exclude_file" then
    return cur_file ~= "" and string.format("EXCLUDE: %s", cur_file) or "EXCLUDE CURRENT FILE"
  elseif mode == "exclude_ext" then
    return cur_ext ~= "" and string.format("EXCLUDE ALL: .%s", cur_ext) or "EXCLUDE EXTENSION"
  elseif mode == "current_file" then
    return cur_file ~= "" and string.format("ONLY: %s", cur_file) or "CURRENT FILE ONLY"
  else
    return "ALL CODE FILES"
  end
end

-- Normaliza la ruta a un path absoluto único
function M.normalize_path(path)
  if not path or path == "" then
    return ""
  end
  local abs = vim.fn.fnamemodify(path, ":p")
  return (vim.uv or vim.loop).fs_realpath(abs) or abs
end

-- Construye los argumentos de filtrado para ripgrep según el modo
function M.build_globs(mode)
  local globs = {}
  local current_file_rel = vim.fn.expand("%:.")
  local current_ext = vim.fn.expand("%:e")

  for _, pattern in ipairs(M.CODE_IGNORE_PATTERNS) do
    table.insert(globs, "-g")
    table.insert(globs, vim.fn.shellescape(pattern))
  end

  if mode == "exclude_file" and current_file_rel ~= "" then
    local exact_glob = current_file_rel:sub(1, 2) == "./" and current_file_rel or ("./" .. current_file_rel)
    table.insert(globs, "-g")
    table.insert(globs, vim.fn.shellescape("!" .. exact_glob))
  elseif mode == "exclude_ext" and current_ext ~= "" then
    table.insert(globs, "-g")
    table.insert(globs, vim.fn.shellescape("!*." .. current_ext))
  elseif mode == "current_file" and current_file_rel ~= "" then
    local exact_glob = current_file_rel:sub(1, 2) == "./" and current_file_rel or ("./" .. current_file_rel)
    table.insert(globs, "-g")
    table.insert(globs, vim.fn.shellescape(exact_glob))
  end

  return globs
end

return M
