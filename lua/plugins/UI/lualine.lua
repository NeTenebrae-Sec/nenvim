local ok, lualine = pcall(require, "lualine")
if not ok then
    return
end

-- =========================================================
-- Helper: Detección inteligente de la raíz del proyecto
-- =========================================================
local function get_intelligent_project_root()
    local current_file = vim.api.nvim_buf_get_name(0)

    -- Si no hay archivo abierto (buffer vacío), usamos el directorio de trabajo de Neovim
    if current_file == "" then
        return vim.fn.getcwd()
    end

    local current_dir = vim.fs.dirname(current_file)

    -- Intentamos buscar un directorio .git hacia arriba partiendo de este archivo
    local git_ancestor = vim.fs.find(".git", { path = current_dir, upward = true })[1]
    if git_ancestor then
        return vim.fs.dirname(git_ancestor)
    end

    -- Si no es un repo Git, la raíz será la carpeta que contiene al archivo actual
    return current_dir
end

-- =========================================================
-- Componentes Personalizados e Inteligentes
-- =========================================================

-- Componente inteligente: Nombre de la carpeta raíz real del proyecto actual
local function cwd_name()
    local root = get_intelligent_project_root()
    return vim.fn.fnamemodify(root, ":t")
end

local function vite_status()
    local project_root = get_intelligent_project_root()
    local server = _G.vite_active_servers and _G.vite_active_servers[project_root]

    if server and server.port then
        return "VITE:" .. server.port
    end
    return ""
end

-- NUEVO: Detectar servidores LSP activos en el buffer actual sin duplicar nombres
local function active_lsp_servers()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if next(clients) == nil then
        return "No LSP"
    end

    local seen = {}
    local lsp_names = {}

    for _, client in ipairs(clients) do
        if not seen[client.name] then
            seen[client.name] = true
            table.insert(lsp_names, client.name)
        end
    end

    return "󰒋 " .. table.concat(lsp_names, ", ")
end

-- =========================================================
-- Configuración de Lualine
-- =========================================================
lualine.setup({
    options = {
        theme = "auto",
        globalstatus = true,
        icons_enabled = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
    },
    sections = {
        lualine_a = {
            {
                "mode",
                separator = { left = "", right = "" },
                padding = { left = 1, right = 1 },
            },
        },
        lualine_b = {
            { cwd_name, icon = "" },
            { "branch", icon = "" },
            { "diff" },
        },
        lualine_c = {
            {
                "filename",
                path = 0,
                symbols = {
                    modified = " ●",
                    readonly = " ",
                    unnamed = "[No Name]",
                },
            },
        },
        lualine_x = {
            {
                vite_status,
                icon = "󰒋",
                color = { fg = "#e0af68", gui = "bold" },
            },
            {
                active_lsp_servers,
                color = { fg = "#7aa2f7", gui = "bold" },
            },
            { "diagnostics" },
            { "filetype" },
        },
        lualine_y = {
            { "progress" },
        },
        lualine_z = {
            {
                "location",
                separator = { left = "", right = "" },
                padding = { left = 1, right = 1 },
            },
        },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },
})
