-- ============================================================
-- NOICE: carga segura
-- ============================================================
local ok, noice = pcall(require, "noice")
if not ok then
    return
end

-- ============================================================
-- NOICE: configuración principal
-- ============================================================
noice.setup({

    -- ----------------------------------------------------------
    -- LSP
    -- ----------------------------------------------------------
    lsp = {
        progress = {
            enabled = true,
            format = "lsp_progress", -- Utiliza el formateador interno que agrupa subtareas
            view = "mini", -- Lo mantiene en tu vista mini abajo a la derecha
        },
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
        },
    },
    -- ----------------------------------------------------------
    -- Cmdline
    -- ----------------------------------------------------------
    cmdline = {
        enabled = true,
        view = "cmdline_popup",
    },

    -- ----------------------------------------------------------
    -- Messages
    -- ----------------------------------------------------------
    messages = {
        enabled = true,
        view = "mini",
    },

    -- ----------------------------------------------------------
    -- Presets
    -- ----------------------------------------------------------
    presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
    },

    -- ----------------------------------------------------------
    -- Views
    -- ----------------------------------------------------------
    views = {
        hover = {
            border = { style = "rounded" },
            win_options = {
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
        },

        signature = {
            border = { style = "rounded" },
            win_options = {
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
        },

        popupmenu = {
            backend = "cmp",
        },
    },

    -- ----------------------------------------------------------
    -- Routes
    -- ----------------------------------------------------------
})
