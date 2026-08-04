-- ============================================================================
-- MODULE: lua/plugins/lsp/formatters/commands.lua
-- PURPOSE: User commands registration (:FormatProject and :FormatInit)
-- ============================================================================

local M = {}

-- 1. LOAD FORMATTER MODULES
local modules = {
  lua = require("plugins.lsp.formatters.lua"),
  javascript = require("plugins.lsp.formatters.javascript"),
  markdown = require("plugins.lsp.formatters.markdown"),
  shell = require("plugins.lsp.formatters.shell"),
}

-- 2. DYNAMIC FILETYPE -> MODULE MAPPING
local formatters_by_ft = {}
for _, mod in pairs(modules) do
  if mod.formatters_by_ft then
    for ft, _ in pairs(mod.formatters_by_ft) do
      formatters_by_ft[ft] = mod
    end
  end
end

--- Registers user commands in Neovim
function M.setup()
  -- ========================================================================
  -- COMMAND 1: :FormatProject
  -- PURPOSE: Formats the entire project in the background using local rules.
  -- ========================================================================
  vim.api.nvim_create_user_command("FormatProject", function(opts)
    local ft = (opts.args ~= "") and opts.args or vim.bo.filetype
    local mod = formatters_by_ft[ft]

    if not mod then
      vim.notify("[FormatProject] Unsupported filetype: " .. tostring(ft), vim.log.levels.WARN)
      return
    end

    local root = vim.fs.root(0, { "package.json", ".git", ".stylua.toml", ".editorconfig" }) or vim.fn.getcwd()

    -- CASE 1: LUA (StyLua)
    if ft == "lua" then
      vim.notify("[FormatProject] Formatting Lua project...", vim.log.levels.INFO)
      local cmd = { "stylua" }
      for _, arg in ipairs(mod.get_cli_args(root)) do
        table.insert(cmd, arg)
      end
      table.insert(cmd, ".")

      vim.system(cmd, { cwd = root }, function(out)
        vim.schedule(function()
          if out.code == 0 then
            vim.notify("[FormatProject] Lua project formatted successfully!", vim.log.levels.INFO)
            vim.cmd("checktime")
          else
            vim.notify("[FormatProject] StyLua error: " .. (out.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end)
      return
    end

    -- CASE 2: WEB ECOSYSTEM / PRETTIER
    if modules.javascript.formatters_by_ft[ft] then
      vim.notify("[FormatProject] Formatting Web project with Prettier...", vim.log.levels.INFO)

      local prettier_bin = root .. "/node_modules/.bin/prettier"
      if vim.fn.executable(prettier_bin) == 0 then
        prettier_bin = "prettier"
      end

      local cmd = { prettier_bin, "--write" }
      for _, arg in ipairs(mod.get_cli_args(root)) do
        table.insert(cmd, arg)
      end
      table.insert(cmd, ".")

      vim.system(cmd, { cwd = root }, function(out)
        vim.schedule(function()
          if out.code == 0 then
            vim.notify("[FormatProject] Web project formatted successfully!", vim.log.levels.INFO)
            vim.cmd("checktime")
          else
            vim.notify("[FormatProject] Prettier error: " .. (out.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end)
      return
    end

    vim.notify("[FormatProject] No project-wide CLI formatter configured for: " .. ft, vim.log.levels.WARN)
  end, {
    desc = "Formats all project files based on active language",
    nargs = "?",
  })

  -- ========================================================================
  -- COMMAND 2: :FormatInit
  -- PURPOSE: Creates local config file (.prettierrc, .stylua.toml, etc.)
  -- ========================================================================
  vim.api.nvim_create_user_command("FormatInit", function(opts)
    local ft = (opts.args ~= "") and opts.args or vim.bo.filetype
    local mod = formatters_by_ft[ft]

    if not mod or not mod.init_config then
      vim.notify("[FormatInit] No config template found for filetype: " .. tostring(ft), vim.log.levels.WARN)
      return
    end

    local root = vim.fs.root(0, { ".git", "package.json" }) or vim.fn.getcwd()
    local target_path = root .. "/" .. mod.init_config.filename

    if vim.uv.fs_stat(target_path) then
      vim.notify("[FormatInit] File " .. mod.init_config.filename .. " already exists.", vim.log.levels.WARN)
      return
    end

    local file, err = io.open(target_path, "w")
    if file then
      file:write(mod.init_config.content)
      file:close()
      vim.notify("[FormatInit] Created " .. mod.init_config.filename .. " in project root.", vim.log.levels.INFO)
    else
      vim.notify("[FormatInit] Error creating file: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, {
    desc = "Generates local formatter configuration file",
    nargs = "?",
  })
end

return M
