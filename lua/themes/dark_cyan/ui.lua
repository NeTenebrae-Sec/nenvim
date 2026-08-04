local M = {}

function M.setup(c, set)
    set("Normal", { fg = c.fg0, bg = c.bg0 })
    set("NormalNC", { fg = c.fg1, bg = c.bg0 })
    set("EndOfBuffer", { fg = "NONE", bg = c.bg0 })
    set("SignColumn", { bg = c.bg0 })

    set("LineNr", { fg = c.border, bg = "NONE" })
    set("CursorLineNr", { fg = c.cyan1, bg = c.bg0, bold = true })

    set("CursorLine", { bg = c.bg1 })
    set("Visual", { fg = c.white, bg = c.deep })
    set("Search", { fg = c.bg0, bg = c.ice, bold = true })
    set("IncSearch", { fg = c.bg0, bg = c.cyan1, bold = true })

    set("VertSplit", { fg = c.border, bg = c.bg0 })
    set("WinSeparator", { fg = c.border, bg = c.bg0 })
    set("ColorColumn", { bg = c.bg1 })

    set("Comment", { fg = c.fg2, italic = true })
    set("NonText", { fg = c.fg2, bg = c.bg0 })
    set("SpecialKey", { fg = c.ice, bg = c.bg3, bold = true })

    set("NormalFloat", { fg = c.fg0, bg = "NONE" })
    set("FloatBorder", { fg = c.cyan1, bg = "NONE" })
end

return M
