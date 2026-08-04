local M = {}

local ENABLED = false
local LOG_FILENAME = "perf_monitor.log"

if not ENABLED then
    return M
end

local project_root = vim.fn.getcwd()
local log_path = project_root .. "/" .. LOG_FILENAME

local function log(msg)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local file = io.open(log_path, "a")
    if file then
        file:write(string.format("[%s] %s\n", timestamp, msg))
        file:close()
    end
end

log("RASTREADOR DE LÍNEA Y COLUMNA ACTIVADO")

-- Contador para no reventar el log si entra en bucle infinito
local filetype_trigger_count = 0
local MAX_TRACES = 10

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PerfFileTypeTrace", { clear = true }),
    callback = function(args)
        filetype_trigger_count = filetype_trigger_count + 1

        if filetype_trigger_count > MAX_TRACES then
            return
        end

        local fname = vim.fn.expand("%:t")
        if fname == "" then
            fname = "<buffer " .. args.buf .. ">"
        end

        log(
            string.format(
                "\n[DISPARO #%d] FileType ejecutado en buffer: '%s' (ID: %d)",
                filetype_trigger_count,
                fname,
                args.buf
            )
        )
        log("PILA DE LLAMADAS (QUIÉN LO INVOCÓ):")

        -- Inspeccionamos la pila hacia atrás para ver la línea y columna exactas
        local level = 2
        while true do
            local info = debug.getinfo(level, "Slnf")
            if not info then
                break
            end

            local source = info.source or "unknown"
            local current_line = info.currentline or -1
            local name = info.name or "<función anónima>"
            local what = info.what

            -- Filtramos librerías internas de C para enfocarnos en los archivos de tus plugins
            if source:sub(1, 1) == "@" then
                local clean_path = source:sub(2)
                log(string.format("   [%s] En función '%s'() | Archivo: %s:%d", what, name, clean_path, current_line))
            end

            level = level + 1
        end
        log("--------------------------------------------------")
    end,
})

return M
