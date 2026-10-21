local extractors = require("plugins.trident.search.extractors")
local filters = require("plugins.trident.search.filters")
local runner = require("plugins.trident.search.runner")

local M = {}

M.get_target_word = extractors.get_target_word
M.get_visual_selection = extractors.get_visual_selection
M.prompt_user_input = extractors.prompt_user_input

M.get_mode_filter_label = filters.get_mode_filter_label
M.normalize_path = filters.normalize_path

M.run_ripgrep = runner.run_ripgrep

return M
