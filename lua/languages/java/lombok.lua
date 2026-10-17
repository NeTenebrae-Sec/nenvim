local M = {}

function M.get_jar_path()
  local home = os.getenv("HOME")
  local lombok_dir = home .. "/.local/share/lombok"
  local lombok_jar = lombok_dir .. "/lombok.jar"

  if vim.fn.filereadable(lombok_jar) == 0 then
    vim.notify("[Java LSP] Lombok JAR not found. Downloading...", vim.log.levels.INFO)
    vim.fn.mkdir(lombok_dir, "p")

    local download_cmd = string.format("curl -sL https://projectlombok.org/downloads/lombok.jar -o %s", vim.fn.shellescape(lombok_jar))
    local res = vim.fn.system(download_cmd)

    if vim.v.shell_error == 0 then
      vim.notify("[Java LSP] Lombok JAR downloaded successfully.", vim.log.levels.INFO)
    else
      vim.notify("[Java LSP] Failed to download Lombok JAR: " .. tostring(res), vim.log.levels.ERROR)
      return ""
    end
  end

  return lombok_jar
end

return M