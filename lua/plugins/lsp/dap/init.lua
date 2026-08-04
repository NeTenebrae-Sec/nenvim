-- lua/plugins/lsp/dap.lua
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
    return
end

local ok_dapui, dapui = pcall(require, "dapui")
if not ok_dapui then
    return
end

local ok_mason_dap, mason_dap = pcall(require, "mason-nvim-dap")
if not ok_mason_dap then
    return
end

mason_dap.setup({
    ensure_installed = {
        "js-debug-adapter",
        "python",
        "bash-debug-adapter",
        "codelldb",
    },
    automatic_installation = true,
})

local mason_path = vim.fn.stdpath("data") .. "/mason"
local js_debug_path = mason_path .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
-- Busca este bloque cerca de la línea 24 de tu archivo actual y reemplázalo:
local bashdb_dir = mason_path .. "/packages/bash-debug-adapter/extension/bashdb_dir"
local bashdb_path = bashdb_dir .. "/bashdb"
local codelldb_adapter = mason_path .. "/packages/codelldb/extension/adapter/codelldb"

-- ===============================
-- Terminal externa para programas interactivos
-- ===============================
dap.defaults.fallback.focus_terminal = true

-- KITTY
dap.defaults.fallback.external_terminal = {
    command = "/usr/bin/kitty",
    args = { "--hold", "-e" },
}

-- Si usas otra terminal, cambia SOLO este bloque:
-- ALACRITTY
-- dap.defaults.fallback.external_terminal = {
--   command = "/usr/bin/alacritty",
--   args = { "-e" },
-- }

-- WEZTERM
-- dap.defaults.fallback.external_terminal = {
--   command = "/usr/bin/wezterm",
--   args = { "start", "--always-new-process", "--" },
-- }

-- GNOME TERMINAL
-- dap.defaults.fallback.external_terminal = {
--   command = "/usr/bin/gnome-terminal",
--   args = { "--" },
-- }

-- ===============================
-- UI
-- ===============================
vim.fn.sign_define("DapBreakpoint", {
    text = "",
    texthl = "DapBreakpoint",
    linehl = "",
    numhl = "",
})

vim.fn.sign_define("DapBreakpointCondition", {
    text = "",
    texthl = "DapBreakpointCondition",
    linehl = "",
    numhl = "",
})

vim.fn.sign_define("DapBreakpointRejected", {
    text = "",
    texthl = "DapBreakpointRejected",
    linehl = "",
    numhl = "",
})

vim.fn.sign_define("DapLogPoint", {
    text = "",
    texthl = "DapLogPoint",
    linehl = "",
    numhl = "",
})

vim.fn.sign_define("DapStopped", {
    text = "",
    texthl = "DapStopped",
    linehl = "Visual",
    numhl = "DiagnosticWarn",
})

dapui.setup({
    icons = {
        expanded = "",
        collapsed = "",
        current_frame = "",
    },
    controls = {
        enabled = true,
        icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "↻",
            terminate = "□",
            disconnect = "",
        },
    },
    layouts = {
        {
            elements = {
                { id = "scopes", size = 0.60 },
                { id = "breakpoints", size = 0.20 },
                { id = "stacks", size = 0.20 },
            },
            size = 40,
            position = "left",
        },
        {
            elements = {
                { id = "watches", size = 1.0 },
            },
            size = 10,
            position = "bottom",
        },
    },
})

-- No abrir/cerrar automáticamente; control manual con <leader>ui
dap.listeners.before.launch["dapui_config"] = function() end
dap.listeners.before.attach["dapui_config"] = function() end
dap.listeners.before.event_terminated["dapui_config"] = function() end
dap.listeners.before.event_exited["dapui_config"] = function() end

local notified = false

dap.listeners.before.launch["debugger_notify"] = function()
    if notified then
        return
    end
    notified = true

    local ok_bp, dap_breakpoints = pcall(require, "dap.breakpoints")
    local has_breakpoints = ok_bp and not vim.tbl_isempty(dap_breakpoints.get())

    if has_breakpoints then
        vim.notify("Starting debugger...", vim.log.levels.INFO)
    else
        vim.notify("Starting debugger without breakpoints.", vim.log.levels.INFO)
    end
end

-- Cuando el debugger se apaga o sale, reiniciamos la bandera para la siguiente ejecución
local function reset_notify()
    notified = false
end

dap.listeners.after.event_terminated["debugger_notify"] = reset_notify
dap.listeners.after.event_exited["debugger_notify"] = reset_notify

-- ===============================
-- JS / TS
-- ===============================
dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = 8124,
    executable = {
        command = "node",
        args = {
            js_debug_path,
            "8124",
            "127.0.0.1",
        },
    },
    options = {
        detached = false,
    },
}

local node_configs = {
    {
        type = "pwa-node",
        request = "launch",
        name = "Launch current file (Node External Terminal)",
        program = "${file}",
        cwd = "${workspaceFolder}",
        console = "externalTerminal",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**" },
    },
    {
        type = "pwa-node",
        request = "attach",
        name = "Attach to process",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**" },
    },
}

dap.configurations.javascript = node_configs
dap.configurations.typescript = node_configs
dap.configurations.javascriptreact = node_configs
dap.configurations.typescriptreact = node_configs

-- ===============================
-- Python
-- ===============================
dap.adapters.python = {
    type = "executable",
    command = "python3",
    args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch current file",
        program = "${file}",
        console = "integratedTerminal",
        pythonPath = function()
            return "python3"
        end,
    },
}

-- ===============================
-- Bash
-- ===============================
dap.adapters.bash = {
    type = "executable",
    command = mason_path .. "/packages/bash-debug-adapter/bash-debug-adapter",
    name = "bashdb",
}

-- Función limpia para pedir argumentos interactivamente
local function get_bash_args()
    local input = vim.fn.input("Arguments (Enter = none): ", "", "file")
    vim.cmd("redraw") -- Limpia la línea de comandos visual de Neovim al dar Enter
    input = vim.trim(input)
    if input == "" then
        return {}
    end
    return vim.split(input, "%s+")
end

dap.configurations.sh = {
    {
        type = "bash",
        request = "launch",
        name = "Launch bash script",
        -- Función dinámica para resolver la ruta absoluta del archivo actual
        program = function()
            return vim.fn.expand("%:p")
        end,
        file = "${file}",
        cwd = "${workspaceFolder}",

        pathBashdb = bashdb_path,
        pathBashdbLib = bashdb_dir,
        pathBash = vim.fn.exepath("bash") ~= "" and vim.fn.exepath("bash") or "/bin/bash",

        pathCat = vim.fn.exepath("cat") ~= "" and vim.fn.exepath("cat") or "cat",
        pathMkfifo = vim.fn.exepath("mkfifo") ~= "" and vim.fn.exepath("mkfifo") or "mkfifo",
        pathPkill = vim.fn.exepath("pkill") ~= "" and vim.fn.exepath("pkill") or "pkill",
        pathGrep = vim.fn.exepath("grep") ~= "" and vim.fn.exepath("grep") or "grep",
        pathSleep = vim.fn.exepath("sleep") ~= "" and vim.fn.exepath("sleep") or "sleep",

        terminalKind = "external", -- Levanta tu terminal externa Kitty configurada en fallbacks
        env = {},
        args = get_bash_args, -- Llama a la función para capturar los argumentos
        argsString = "",

        showDebugOutput = false,
        trace = false,
    },
}

dap.configurations.bash = dap.configurations.sh

-- COMPILER CONFIG
-- TODO MODULARIZAR ESTO

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
        -- Usamos vim.notify en lugar de error() para ver qué falló sin romper Neovim
        vim.notify("Compilación fallida:\n" .. result, vim.log.levels.ERROR)
        return "" -- Devolvemos un string vacío para que DAP se detenga limpiamente
    end

    if vim.fn.executable(target) == 0 then
        vim.notify("No se encontró el ejecutable generado: " .. target, vim.log.levels.ERROR)
        return ""
    end

    return target
end

local function run_c_in_kitty()
    local exe = build_c_target()
    vim.fn.jobstart({
        "/usr/bin/kitty",
        "--hold",
        "-e",
        exe,
    }, { detach = true })
end

-- ===============================
-- C / C++
-- ===============================
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
        program = function()
            return build_c_target()
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}

dap.configurations.cpp = dap.configurations.c

-- ===============================
-- Comandos de Usuario y Keymaps
-- ===============================

vim.api.nvim_create_user_command("CRun", function()
    run_c_in_kitty()
end, {})

vim.keymap.set("n", "<leader>cr", run_c_in_kitty, { desc = "Run C in Kitty" })

vim.api.nvim_create_user_command("CMakefileInit", ensure_makefile, {})
