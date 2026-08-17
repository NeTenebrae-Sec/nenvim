-- ==========================================================================
-- vimpack: init.lua (Central Orchestrator)
-- ==========================================================================
local plugins = require("config.vimpack.plugins")
local config_manager = require("config.vimpack.config")
local ui_manager = require("config.vimpack.ui")

local M = {}

-- ==========================================================================
-- USER-CONFIGURABLE MESSAGES (Localization)
-- ==========================================================================
M.messages = {
  bootstrap_cloning = "Cloning initial bootstrap: ",
  install_success = "Installed: ",
  install_failed = "Clone failed: ",
  update_success = "Updated: ",
  update_uptodate = "Up to date: ",
  update_failed = "Update failed: ",
  clean_not_found = "Directory pack/plugins/start not found.",
  clean_deleted = "Obsolete package deleted: ",
  clean_success = "Clean! All folders match your plugins list.",
  err_unknown_clone = "Clone error",
  err_unknown_pull = "Conflict or network error",
}

-- [NATIVE BOOTSTRAP] Synchronous initial cloning before full startup
M.bootstrap = function()
  for _, plugin in ipairs(plugins.list) do
    local path = plugins.path .. "/" .. plugin.dest
    if vim.fn.empty(vim.fn.glob(path)) == 1 then
      vim.notify(M.messages.bootstrap_cloning .. plugin.dest, vim.log.levels.WARN)
      vim.fn.system({ "git", "clone", "--depth=1", "--filter=blob:none", plugin.url, path })
    end
  end
end

-- [ASYNCHRONOUS] Parallel synchronization via controlled concurrent pool
M.update = function()
  local ui = ui_manager.open(#plugins.list)
  local tasks = {}
  local errors = {}

  for _, plugin in ipairs(plugins.list) do
    table.insert(tasks, function(done)
      local path = plugins.path .. "/" .. plugin.dest
      local name = plugin.dest:gsub("start/", "")

      vim.uv.fs_stat(path, function(err, stat)
        local is_empty = (err or not stat)

        if is_empty then
          vim.system({ "git", "clone", "--depth=1", "--filter=blob:none", plugin.url, path }, {}, function(obj)
            if obj.code == 0 then
              ui_manager.update_progress(ui, M.messages.install_success .. name)
              if plugin.build then
                vim.schedule(function()
                  pcall(vim.cmd, plugin.build)
                end)
              end
            else
              local clean_err = (obj.stderr or M.messages.err_unknown_clone):gsub("\n", " ")
              table.insert(errors, { name = name, msg = clean_err })
              ui_manager.update_progress(ui, M.messages.install_failed .. name)
            end
            done()
          end)
        else
          vim.system({ "git", "-C", path, "pull", "--ff-only", "--rebase=false" }, {}, function(obj)
            if obj.code == 0 then
              local out = obj.stdout or ""
              if not out:find("Already up to date") and not out:find("Ya está al día") then
                ui_manager.update_progress(ui, M.messages.update_success .. name)
                if plugin.build then
                  vim.schedule(function()
                    pcall(vim.cmd, plugin.build)
                  end)
                end
              else
                ui_manager.update_progress(ui, M.messages.update_uptodate .. name)
              end
            else
              local clean_err = (obj.stderr or M.messages.err_unknown_pull):gsub("\n", " ")
              table.insert(errors, { name = name, msg = clean_err })
              ui_manager.update_progress(ui, M.messages.update_failed .. name)
            end
          end)
          vim.schedule(done)
        end
      end)
    end)
  end

  ui_manager.run_concurrent_pool(tasks, 5, function()
    ui_manager.close(ui, errors)
  end)
end

-- ==========================================================================
-- GLOBAL USER COMMANDS
-- ==========================================================================
vim.api.nvim_create_user_command("PackUpdate", M.update, { desc = "Update/Sync plugins" })

vim.api.nvim_create_user_command("PackClean", function()
  local start_path = plugins.path .. "/start"
  local handle = vim.uv.fs_scandir(start_path)
  if not handle then
    vim.notify(M.messages.clean_not_found, vim.log.levels.ERROR)
    return
  end

  local valid_plugins = {}
  for _, plugin in ipairs(plugins.list) do
    local name = plugin.dest:gsub("start/", "")
    valid_plugins[name] = true
  end

  local deleted_any = false
  while true do
    local name, type_name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if (type_name == "directory" or type_name == "link") and not valid_plugins[name] then
      local target_dir = start_path .. "/" .. name
      vim.fn.delete(target_dir, "rf")
      vim.notify(M.messages.clean_deleted .. name, vim.log.levels.WARN)
      deleted_any = true
    end
  end

  if not deleted_any then
    vim.notify(M.messages.clean_success, vim.log.levels.INFO)
  end
end, { desc = "Clean/Uninstall unused plugins" })

-- Safe native execution of configuration loaders
config_manager.load_all()

return M
