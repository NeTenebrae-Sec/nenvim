local search = require("plugins.trident.search")
local editor = require("plugins.trident.editor")
local menu = require("plugins.trident.menu")

local M = {}

function M.inspect_and_edit(mode)
  local word = search.get_target_word()
  if not word or word == "" then
    vim.notify("Trident: No valid word found under cursor", vim.log.levels.WARN)
    return
  end

  local filter_label = search.get_mode_filter_label(mode)
  local results = search.run_ripgrep(word, mode)

  if #results == 0 then
    vim.notify(string.format("Trident: No matches found for '%s' [%s]", word, filter_label), vim.log.levels.WARN)
    return
  end

  if #results == 1 then
    editor.open_floating_editor(results[1].file, results[1].lnum, results[1].col, filter_label)
  else
    menu.open_selection_menu(results, filter_label, word)
  end
end

function M.open_last_buffer()
  if not editor.last_selected then
    vim.notify("Trident: No previous buffer recorded", vim.log.levels.WARN)
    return
  end
  editor.open_floating_editor(
    editor.last_selected.file,
    editor.last_selected.lnum,
    editor.last_selected.col,
    editor.last_selected.label or "LAST BUFFER"
  )
end

function M.setup()
  local opts = { silent = true }

  vim.keymap.set("n", "tt", function()
    M.inspect_and_edit("all")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Peek All Files" }))

  vim.keymap.set("n", "tr", function()
    M.inspect_and_edit("exclude_file")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current File" }))

  vim.keymap.set("n", "te", function()
    M.inspect_and_edit("exclude_ext")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current Extension" }))

  vim.keymap.set("n", "tl", function()
    M.open_last_buffer()
  end, vim.tbl_extend("force", opts, { desc = "Trident: Open Last Buffer" }))
end

-- Ejecuta la definición de keymaps al momento de cargar el módulo
M.setup()

return M
