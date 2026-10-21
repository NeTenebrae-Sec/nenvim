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
require("config.rpc") -- RPC socket for nvim-mcp (specs/tasks/000).
require("config.patches") -- Parches de plugins de terceros (specs/tasks/003).

require("config.vimpack")
