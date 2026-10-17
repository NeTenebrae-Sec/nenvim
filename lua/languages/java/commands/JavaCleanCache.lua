local M = {}

function M.clean()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    vim.notify("JDTLS is not active in this buffer", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  local home = os.getenv("HOME")

  -- Detect project root to find the specific workspace folder name
  local root_dir = jdtls.setup.find_root({
    "pom.xml",
    "build.gradle",
    "gradlew",
    "mvnw",
    ".git",
    ".project",
    ".classpath",
    ".java-version",
  }) or vim.fn.expand("%:p:h")

  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

  if vim.fn.isdirectory(workspace_dir) == 1 then
    vim.fn.delete(workspace_dir, "rf")
    vim.notify("Workspace cache cleared for project: " .. project_name, vim.log.levels.INFO, {
      title = "Java LSP",
    })
  else
    vim.notify("No cache folder found for project: " .. project_name, vim.log.levels.WARN, {
      title = "Java LSP",
    })
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaCleanCache", function()
    M.clean()
  end, {
    desc = "Clear JDTLS workspace cache for the current project",
  })
end

return M
