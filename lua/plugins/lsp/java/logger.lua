local M = {}

local log_file = os.getenv("HOME") .. "/.cache/jdtls/java_init_debug.log"

function M.debug(msg, data)
  vim.fn.mkdir(os.getenv("HOME") .. "/.cache/jdtls", "p")
  local file = io.open(log_file, "a")
  if file then
    local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
    file:write(timestamp .. " " .. msg .. "\n")
    if data ~= nil then
      if type(data) == "table" then
        file:write(vim.inspect(data) .. "\n")
      else
        file:write(tostring(data) .. "\n")
      end
    end
    file:write("--------------------------------------------------\n")
    file:close()
  end
end

return M
