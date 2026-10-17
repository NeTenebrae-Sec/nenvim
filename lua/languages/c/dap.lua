local M = {}

local function ensure_makefile()
  local cwd = vim.fn.getcwd()
  local makefile_path = cwd .. "/Makefile"

  if vim.fn.filereadable(makefile_path) == 1 or vim.fn.filereadable(cwd .. "/makefile") == 1 then
    return
  end

  local content = {
    "CC = gcc",
    "CFLAGS = -Wall -Wextra -g -Iinclude",
    "LDFLAGS =",
    "LDLIBS =",
    "",
    "TARGET = main",
    "SRCS = $(wildcard *.c src/*.c)",
    "OBJS = $(SRCS:.c=.o)",
    "",
    "all: $(TARGET)",
    "",
    "$(TARGET): $(OBJS)",
    "\t$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS) $(LDLIBS)",
    "",
    "%.o: %.c",
    "\t$(CC) $(CFLAGS) -c $< -o $@",
    "",
    "run: $(TARGET)",
    "\t./$(TARGET)",
    "",
    "clean:",
    "\trm -f $(OBJS) $(TARGET)",
    "",
    ".PHONY: all run clean",
  }

  vim.fn.writefile(content, makefile_path)
  vim.notify("Makefile not detected, created file.", vim.log.levels.INFO)
end

local function build_c_target()
  ensure_makefile()
  local cwd = vim.fn.getcwd()
  local target = cwd .. "/main"

  local result = vim.fn.system({ "make", "-C", cwd })
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilación fallida:\n" .. result, vim.log.levels.ERROR)
    return ""
  end

  if vim.fn.executable(target) == 0 then
    vim.notify("No se encontró el ejecutable generado: " .. target, vim.log.levels.ERROR)
    return ""
  end

  return target
end

--- Lógica de ejecución directa para C / C++
function M.run()
  local exe = build_c_target()
  if exe ~= "" then
    local cmd = string.format("%s; echo ''; read -p 'Presiona Enter para cerrar...'", vim.fn.shellescape(exe))
    vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
  end
end

function M.setup(dap, mason_path)
  local codelldb_adapter = mason_path .. "/packages/codelldb/extension/adapter/codelldb"

  dap.adapters.codelldb = {
    type = "executable",
    command = codelldb_adapter,
    name = "codelldb",
  }

  dap.configurations.c = {
    {
      name = "Debug current C file",
      type = "codelldb",
      request = "launch",
      program = build_c_target,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }

  dap.configurations.cpp = dap.configurations.c
  vim.api.nvim_create_user_command("CMakefileInit", ensure_makefile, {})
end

return M
