-- =========================================================
-- commands.lua
-- Autocomandos y Comandos de Usuario (User Commands)
-- =========================================================

-- === AUTOCOMANDOS ===

-- 1. Resaltar texto copiado (Yank)
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Resalta el texto copiado",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
    end,
})

-- 2. Restaurar última posición del cursor al abrir un archivo
vim.api.nvim_create_autocmd("BufReadPost", {
    desc = "Restaura la posición previa del cursor",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ============================================================================
-- SYSTEM DEBUGGER (NO EMOJIS / VIMPAC 0.12 COMPATIBLE)
-- ============================================================================

local function generate_debug_report()
    local log_file = vim.fn.getcwd() .. "/nvim_debug.log"
    local lines = {}

    table.insert(lines, "======================================================================")
    table.insert(lines, "SYSTEM CRITICAL / NEOVIM FULL DIAGNOSTIC DUMP")
    table.insert(lines, "TIMESTAMP: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "======================================================================\n")

    -- 1. NEOVIM VERSION & OS CONTEXT
    table.insert(lines, "--- [ NEOVIM VERSION & ENVIRONMENT CONTEXT ] ---")
    local v = vim.version()
    table.insert(lines, string.format("Neovim Version : %d.%d.%d", v.major, v.minor, v.patch))

    local api_info = vim.fn.api_info()
    if api_info and api_info.version and api_info.version.commit then
        table.insert(lines, "Git Commit     : " .. api_info.version.commit)
    end

    -- System OS Details
    local os_name = "Unknown"
    if vim.fn.has("win32") == 1 then
        os_name = "Windows"
    elseif vim.fn.has("mac") == 1 then
        os_name = "macOS"
    elseif vim.fn.has("unix") == 1 then
        local uname = vim.fn.system("uname -sr"):gsub("\n", "")
        os_name = (uname ~= "") and uname or "Linux/Unix"
    end
    table.insert(lines, "Operating System: " .. os_name)
    table.insert(lines, "Working Dir     : " .. vim.fn.getcwd())
    table.insert(lines, "Current Filetype: " .. (vim.bo.filetype ~= "" and vim.bo.filetype or "<NONE>"))

    -- 2. PLUGIN MANAGER & INSTALLED PLUGINS (VIMPAC 0.12 / PACK)
    table.insert(lines, "\n--- [ PLUGIN MANAGER & INSTALLED PLUGINS CONTEXT ] ---")
    table.insert(lines, "Plugin Manager Detected: vimpac / vim.pack (Neovim 0.12+ Native)")

    -- Inspect packages loaded via vimpac or packpath
    local pack_paths = vim.opt.packpath:get()
    table.insert(lines, "Packpath directory entries: " .. #pack_paths)

    local loaded_plugins = {}
    for _, path in ipairs(pack_paths) do
        local start_dir = path .. "/pack/*/start/*"
        local opt_dir = path .. "/pack/*/opt/*"
        for _, p in ipairs(vim.fn.glob(start_dir, true, true)) do
            table.insert(loaded_plugins, "  [START] " .. vim.fn.fnamemodify(p, ":t") .. " (" .. p .. ")")
        end
        for _, p in ipairs(vim.fn.glob(opt_dir, true, true)) do
            table.insert(loaded_plugins, "  [OPT]   " .. vim.fn.fnamemodify(p, ":t") .. " (" .. p .. ")")
        end
    end

    if #loaded_plugins > 0 then
        table.insert(lines, string.format("Total Installed Packages Found: %d\n", #loaded_plugins))
        for _, plug_info in ipairs(loaded_plugins) do
            table.insert(lines, plug_info)
        end
    else
        table.insert(lines, "No packages found in standard packpath directories.")
    end

    -- 3. LOADED BUFFERS & FULL FILE PATHS
    table.insert(lines, "\n--- [ LOADED BUFFERS & FILE PATHS ] ---")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local full_path = vim.api.nvim_buf_get_name(buf)
            full_path = (full_path == "") and "<UNNAMED / SPECIAL BUFFER>" or full_path
            local ft = vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "none"
            local mod = vim.bo[buf].modified and "MODIFIED" or "CLEAN"
            local modifiable = vim.bo[buf].modifiable and "YES" or "NO (READ-ONLY)"

            table.insert(
                lines,
                string.format(
                    "  * Buf #%d: '%s'\n    |- Type: %-10s | Status: %-11s | Modifiable: %s",
                    buf,
                    full_path,
                    ft,
                    mod,
                    modifiable
                )
            )
        end
    end

    -- 4. ACTIVE LSP CLIENTS STATUS
    table.insert(lines, "\n--- [ ACTIVE LSP CLIENTS ] ---")
    local clients = vim.lsp.get_clients()
    if #clients == 0 then
        table.insert(lines, "NO ACTIVE LSP CLIENTS ATTACHED TO THIS SESSION.")
    else
        for _, client in ipairs(clients) do
            local attached_bufs = vim.tbl_keys(client.attached_buffers or {})
            table.insert(
                lines,
                string.format(
                    "  * LSP ID: %d | Server: '%s' | Attached Buffers: [%s]",
                    client.id,
                    client.name,
                    table.concat(attached_bufs, ", ")
                )
            )
        end
    end

    -- 5. RECENT MESSAGES & ERROR LOGS
    table.insert(lines, "\n--- [ RECENT MESSAGES & ERROR HISTORY ] ---")
    local messages = vim.fn.execute("messages")
    if messages:match("%S") then
        table.insert(lines, messages)
    else
        table.insert(lines, "No recent messages, warnings, or errors registered.")
    end

    table.insert(lines, "\n======================================================================")
    table.insert(lines, "END OF DIAGNOSTIC REPORT")
    table.insert(lines, "======================================================================")

    -- WRITE TO FILE
    local file = io.open(log_file, "w")
    if file then
        file:write(table.concat(lines, "\n"))
        file:close()

        vim.notify("DEBUG REPORT GENERATED AT: " .. log_file, vim.log.levels.WARN, {
            title = "SYSTEM DIAGNOSTIC DUMP COMPLETE",
            timeout = 5000,
        })

        vim.cmd("split " .. log_file)
    else
        vim.notify("FATAL ERROR: COULD NOT WRITE DEBUG LOG TO DISK", vim.log.levels.ERROR, {
            title = "IO WRITE FAILURE",
            timeout = 5000,
        })
    end
end

-- Command :Debug
vim.api.nvim_create_user_command("Debug", generate_debug_report, {})

-- Keymap <leader>db
vim.keymap.set("n", "<leader>db", generate_debug_report, { desc = "Generate Complete System Debug Report" })
