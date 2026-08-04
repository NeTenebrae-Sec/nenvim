-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/init.lua
-- PROPÓSITO: Loader dinámico, orquestador de Conform.nvim y registro de :FormatInit
-- COMPATIBILIDAD: Neovim 0.10+ / 0.12 (Usa vim.fs.root nativo)
-- ============================================================================

-- 1. CARGA SEGURA DE DEPENDENCIAS
local ok_conform, conform = pcall(require, "conform")
if not ok_conform then
    return
end

-- 2. REGISTRO DE SUBMÓDULOS DE FORMATEO
local modules = {
    "plugins.lsp.formatters.javascript",
    "plugins.lsp.formatters.markdown",
    "plugins.lsp.formatters.lua",
    "plugins.lsp.formatters.shell",
    "plugins.lsp.formatters.generic",
}

-- 3. ESTRUCTURAS DE DATOS (ESTADO)
local combined_formatters_by_ft = {}
local combined_formatters = {}
local init_configs = {}

-- 4. FUSIÓN DINÁMICA DE CONFIGURACIONES
for _, mod_path in ipairs(modules) do
    local ok, mod = pcall(require, mod_path)
    if ok and type(mod) == "table" then
        -- Mapeo de filetype -> formateadores
        if mod.formatters_by_ft then
            combined_formatters_by_ft = vim.tbl_deep_extend("force", combined_formatters_by_ft, mod.formatters_by_ft)
        end

        -- Anulación / personalización de parámetros de CLI
        if mod.formatters then
            combined_formatters = vim.tbl_deep_extend("force", combined_formatters, mod.formatters)
        end

        -- Registro de plantillas para :FormatInit
        if mod.init_config and mod.formatters_by_ft then
            for ft, _ in pairs(mod.formatters_by_ft) do
                init_configs[ft] = mod.init_config
            end
        end
    end
end

-- 5. INICIALIZACIÓN Y CONFIGURACIÓN DE CONFORM.NVIM
conform.setup({
    formatters_by_ft = combined_formatters_by_ft,
    formatters = combined_formatters,
    format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
    },
})

-- 6. REGISTRO DEL COMANDO DE USUARIO (:FormatInit)
vim.api.nvim_create_user_command("FormatInit", function(opts)
    local ft = (opts.args ~= "") and opts.args or vim.bo.filetype
    local config = init_configs[ft]

    if not config then
        vim.notify("[FormatInit] No hay plantilla registrada para: " .. tostring(ft), vim.log.levels.WARN)
        return
    end

    -- Detección de la raíz del proyecto usando el motor de Nvim 0.10+
    local root = vim.fs.root(0, { "package.json", ".git", "Makefile", ".stylua.toml" }) or vim.fn.getcwd()
    local target_path = root .. "/" .. config.filename

    if vim.fn.filereadable(target_path) == 1 then
        vim.notify("[FormatInit] El archivo '" .. config.filename .. "' ya existe.", vim.log.levels.WARN)
        return
    end

    local file = io.open(target_path, "w")
    if file then
        file:write(config.content)
        file:close()
        vim.notify("[FormatInit] Creado exitosamente: " .. config.filename, vim.log.levels.INFO)
    else
        vim.notify("[FormatInit] Error al escribir en: " .. target_path, vim.log.levels.ERROR)
    end
end, {
    desc = "Genera el archivo de configuración del formateador para el filetype actual/especificado",
    nargs = "?",
    complete = function()
        local keys = {}
        for k in pairs(init_configs) do
            table.insert(keys, k)
        end
        table.sort(keys)
        return keys
    end,
})

-- ============================================================================
-- 7. REGISTRO DEL COMANDO DE USUARIO (:FormatProject)
-- PROPÓSITO: Formatea todos los archivos del proyecto basándose en el filetype.
-- ============================================================================
vim.api.nvim_create_user_command("FormatProject", function(opts)
    local ft = (opts.args ~= "") and opts.args or vim.bo.filetype
    local root = vim.fs.root(0, { "package.json", ".git", "Makefile", ".stylua.toml" }) or vim.fn.getcwd()

    -- 1. PROYECTO LUA (StyLua)
    if ft == "lua" then
        vim.notify("[FormatProject] Formateando proyecto Lua con StyLua...", vim.log.levels.INFO)
        vim.system({ "stylua", "--indent-type", "Spaces", "--indent-width", "4", "." }, { cwd = root }, function(out)
            vim.schedule(function()
                if out.code == 0 then
                    vim.notify("[FormatProject] ✨ ¡Proyecto Lua formateado con éxito!", vim.log.levels.INFO)
                    vim.cmd("checktime")
                else
                    vim.notify(
                        "[FormatProject] ❌ Error al formatear Lua: " .. (out.stderr or ""),
                        vim.log.levels.ERROR
                    )
                end
            end)
        end)
        return
    end

    -- 2. PROYECTO WEB / JS / TS (Prettier)
    local web_fts = {
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
        vue = true,
        svelte = true,
        astro = true,
        html = true,
        css = true,
        scss = true,
        json = true,
        yaml = true,
    }

    if web_fts[ft] then
        vim.notify("[FormatProject] Formateando proyecto con Prettier...", vim.log.levels.INFO)

        local prettier_bin = root .. "/node_modules/.bin/prettier"
        if vim.fn.executable(prettier_bin) == 0 then
            prettier_bin = "prettier"
        end

        local cmd = {
            prettier_bin,
            "--write",
            "--no-editorconfig",
            "--tab-width",
            "4",
            "--use-tabs",
            "true",
            "--semi",
            "true",
            "--single-quote",
            "true",
            "--trailing-comma",
            "all",
            ".",
        }

        vim.system(cmd, { cwd = root }, function(out)
            vim.schedule(function()
                if out.code == 0 then
                    vim.notify("[FormatProject] ✨ ¡Proyecto Web formateado con éxito!", vim.log.levels.INFO)
                    vim.cmd("checktime")
                else
                    vim.notify("[FormatProject] ❌ Error en Prettier: " .. (out.stderr or ""), vim.log.levels.ERROR)
                end
            end)
        end)
        return
    end

    vim.notify("[FormatProject] Tipo de archivo no soportado: " .. tostring(ft), vim.log.levels.WARN)
end, {
    desc = "Formatea todos los archivos del proyecto actual (Soporta Lua, JS, TS, HTML, CSS, JSON, etc.)",
    nargs = "?",
    complete = function()
        return { "lua", "javascript", "typescript", "javascriptreact", "typescriptreact", "html", "css", "json" }
    end,
})
