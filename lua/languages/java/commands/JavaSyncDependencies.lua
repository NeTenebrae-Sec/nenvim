local M = {}

local detector = require("languages.java.commands.JavaAddDependencies.detector")
local java_refresh = require("languages.java.commands.JavaRefresh")

function M.sync()
  local project = detector.detect()

  if project.no_build_tool then
    vim.notify("No Maven/Gradle project found in current directory", vim.log.levels.WARN)
    return
  end

  local sync_cmd
  if project.tool == "maven" then
    sync_cmd = project.cmd .. " dependency:resolve -U dependency:resolve-plugins -U"
  else
    sync_cmd = project.cmd .. " dependencies --refresh-dependencies"
  end

  vim.notify("Syncing " .. project.tool .. " dependencies...", vim.log.levels.INFO)

  vim.fn.jobstart(sync_cmd, {
    cwd = project.root,
    stdout_buffered = true,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("Dependencies synced successfully!", vim.log.levels.INFO)
        java_refresh.refresh({ silent = true })
      else
        vim.notify("Failed to sync dependencies (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("JavaSyncDependencies", M.sync, {
    desc = "Sync Maven/Gradle dependencies and refresh JDTLS workspace",
  })
end

return M
