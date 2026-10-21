local search = require("plugins.trident.search")
local editor = require("plugins.trident.editor")
local menu = require("plugins.trident.menu")
local renamer = require("plugins.trident.renamer")
local M = {}

function M.inspect_and_edit(mode, word_override)
  local word = word_override or search.get_target_word()
  if not word or word == "" then
    vim.notify("Trident: No valid word selected or under cursor", vim.log.levels.WARN)
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

function M.prompt_and_search(mode)
  search.prompt_user_input(function(input_word)
    M.inspect_and_edit(mode or "all", input_word)
  end)
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

  -- Mapeos en Normal Mode
  vim.keymap.set("n", "TT", function()
    M.inspect_and_edit("all")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Peek All Files" }))

  vim.keymap.set("n", "TC", function()
    M.inspect_and_edit("current_file")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Peek Current File Only" }))

  vim.keymap.set("n", "TR", function()
    M.inspect_and_edit("exclude_file")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current File" }))

  vim.keymap.set("n", "TE", function()
    M.inspect_and_edit("exclude_ext")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current Extension" }))

  vim.keymap.set("n", "TL", function()
    M.open_last_buffer()
  end, vim.tbl_extend("force", opts, { desc = "Trident: Open Last Buffer" }))

  vim.keymap.set("n", "T/", function()
    M.prompt_and_search("all")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Search Prompt (All Files)" }))

  local function trigger_visual_search(mode)
    local selected_text = search.get_visual_selection()
    M.inspect_and_edit(mode, selected_text)
  end

  -- Mapeos en Visual Mode
  vim.keymap.set("x", "tt", function()
    trigger_visual_search("all")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Peek Visual All Files" }))

  vim.keymap.set("x", "tc", function()
    trigger_visual_search("current_file")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Peek Current File Only (Visual)" }))

  vim.keymap.set("x", "tr", function()
    trigger_visual_search("exclude_file")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current File (Visual)" }))

  vim.keymap.set("x", "te", function()
    trigger_visual_search("exclude_ext")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Exclude Current Extension (Visual)" }))

  vim.keymap.set("x", "t/", function()
    M.prompt_and_search("all")
  end, vim.tbl_extend("force", opts, { desc = "Trident: Search Prompt (Visual)" }))

  vim.keymap.set("n", "T:", function()
    renamer.rename_live_preview()
  end, { desc = "Trident: Custom Live Rename Floating Window" })
end

-- Ejecuta la definición de keymaps al momento de cargar el módulo
M.setup()

return M
