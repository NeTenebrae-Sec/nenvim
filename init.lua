-- =========================================================
-- init.lua
-- Main entry point with local package management.
-- =========================================================

-- =========================================================
-- LOAD CONFIGURATION
-- =========================================================
require("config.options") -- Load options.
require("config.commands") -- Load commands.
require("config.keymaps") -- Load keymaps.

require("config.vimpack")
