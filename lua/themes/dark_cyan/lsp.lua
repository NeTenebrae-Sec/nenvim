local M = {}

function M.setup(c, set)
    set("DiagnosticError", { fg = c.error1 })
    set("DiagnosticWarn", { fg = c.warn1 })
    set("DiagnosticInfo", { fg = c.blue })
    set("DiagnosticHint", { fg = c.cyan2 })

    set("DiagnosticSignError", { fg = c.error1, bg = c.bg0 })
    set("DiagnosticSignWarn", { fg = c.warn1, bg = c.bg0 })
    set("DiagnosticSignInfo", { fg = c.blue, bg = c.bg0 })
    set("DiagnosticSignHint", { fg = c.cyan2, bg = c.bg0 })

    set("DiagnosticVirtualTextError", { fg = c.error1, bg = "NONE", italic = true })
    set("DiagnosticVirtualTextWarn", { fg = c.warn2, bg = "NONE", italic = true })

    set("DiagnosticUnderlineError", { undercurl = true, sp = c.error1 })
    set("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warn1 })

    set("LspInlayHint", { fg = c.fg2, bg = c.bg1, italic = true })

    set("LspReferenceText", { fg = c.ice, bg = "NONE", bold = true, underline = true })
    set("LspReferenceRead", { fg = c.ice, bg = "NONE", bold = true, underline = true })
    set("LspReferenceWrite", { fg = c.cyan1, bg = "NONE", bold = true, underline = true })
end

return M
