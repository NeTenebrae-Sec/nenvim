local M = {}

function M.setup(c, set)
  -- 1. ESTRUCTURAS Y CONTROL
  set("@keyword", { fg = c.red_neon, bold = true })
  set("@keyword.conditional", { fg = c.red_neon, bold = true })
  set("@keyword.repeat", { fg = c.red_neon, bold = true })
  set("@keyword.coroutine", { fg = c.red_neon, bold = true })
  set("@keyword.function", { fg = c.red_neon, bold = true })
  set("@keyword.operator", { fg = c.red_dark })
  set("@storageclass", { fg = c.red_dark })
  set("@operator", { fg = c.red_dark })

  set("@keyword.exception", { fg = c.red_return, bold = true })
  set("@keyword.debug", { fg = c.warn2, bold = true })
  set("@keyword.directive", { fg = c.purple, bold = true })
  set("@keyword.directive.define", { fg = c.purple, bold = true })
  set("@keyword.type", { fg = c.mint_class, bold = true })
  set("@keyword.modifier", { fg = c.red_dark, italic = true })

  set("@keyword.return", { fg = c.red_return, bold = true })
  set("@exception", { fg = c.red_return, bold = true })

  set("@keyword.import", { fg = c.lime_import, bold = true })
  set("@keyword.export", { fg = c.lime_import, bold = true })

  -- 2. FUNCIONES / LLAMADAS / DEFINICIONES
  set("@function", { fg = c.pink_light, bold = true })
  set("@function.call", { fg = c.pink_light })

  set("@function.method", { fg = c.pink_light, italic = true })
  set("@function.method.call", { fg = c.pink_light, italic = true })
  set("@method", { fg = c.pink_light, italic = true })
  set("@method.call", { fg = c.pink_light, italic = true })

  set("@function.builtin", { fg = c.cyan_neon, bold = true })
  set("@constructor", { fg = c.mint_class, bold = true })
  set("@function.macro", { fg = c.pink, bold = true })

  -- 3. VARIABLES / POO / PROPIEDADES
  set("@variable", { fg = c.white })
  set("@variable.member", { fg = c.white })
  set("@variable.parameter", { fg = c.fg3, italic = true })

  set("@property", { fg = c.yellow_light })
  set("@field", { fg = c.yellow_light })

  set("@variable.builtin", { fg = c.cyan_neon, italic = true })
  set("@variable.parameter.builtin", { fg = c.cyan_neon, italic = true })
  set("@module.builtin", { fg = c.lime_import, italic = true })
  set("@type.qualifier", { fg = c.mint_class, italic = true })

  set("@type", { fg = c.mint_class, bold = true })
  set("@type.definition", { fg = c.mint_class })
  set("@type.builtin", { fg = c.cyan_neon, bold = true })
  set("@structure", { fg = c.mint_class, bold = true })

  set("@namespace", { fg = c.lime_import, italic = true })
  set("@module", { fg = c.lime_import, italic = true })
  set("@label", { fg = c.cyan_neon })

  -- 4. LITERALES DE DATOS
  set("@string", { fg = c.cyan_soft })
  set("@character", { fg = c.cyan_soft })
  set("@string.special", { fg = c.cyan_neon })
  set("@string.special.path", { fg = c.lime_import })
  set("@string.special.url", { fg = c.cyan_soft, underline = true })
  set("@string.regex", { fg = c.pink })
  set("@string.escape", { fg = c.pink, bold = true })

  set("@number", { fg = c.orange })
  set("@boolean", { fg = c.yellow, bold = true })
  set("@constant", { fg = c.orange, bold = true })
  set("@constant.builtin", { fg = c.cyan_neon, bold = true })
  set("@constant.macro", { fg = c.pink, bold = true })

  set("@number.float", { fg = c.orange })
  set("@string.documentation", { fg = c.cyan_soft, italic = true })
  set("@character.special", { fg = c.pink })
  set("@string.special.symbol", { fg = c.cyan_neon })

  -- 5. PUNTUACIÓN / COMENTARIOS
  set("@punctuation.bracket", { fg = c.fg2 })
  set("@punctuation.delimiter", { fg = c.bg4 })
  set("@comment", { fg = c.fg2, italic = true })
  set("@comment.documentation", { fg = c.fg1, italic = true })

  set("@comment.todo", { fg = c.bg0, bg = c.yellow, bold = true })
  set("@comment.warning", { fg = c.bg0, bg = c.warn2, bold = true })
  set("@comment.error", { fg = c.white, bg = c.error1, bold = true })
  set("@attribute", { fg = c.pink, italic = true })

  set("@punctuation.special", { fg = c.pink })
  set("@comment.note", { fg = c.bg0, bg = c.blue, bold = true })
  set("@comment.info", { fg = c.bg0, bg = c.cyan_neon, bold = true })

  -- 6. MARKUP / HTML / MD
  set("@markup.heading", { fg = c.white, bold = true })
  set("@markup.strong", { fg = c.white, bold = true })
  set("@markup.italic", { fg = c.fg1, italic = true })
  set("@markup.raw", { fg = c.cyan_neon, bg = c.bg1 })
  set("@markup.raw.block", { fg = c.cyan_soft, bg = c.bg1 })

  set("@markup.link", { fg = c.pink, underline = true })
  set("@markup.link.label", { fg = c.fg1 })
  set("@markup.link.url", { fg = c.cyan_soft, underline = true })

  set("@markup.strikethrough", { strikethrough = true, fg = c.fg2 })
  set("@markup.underline", { underline = true, fg = c.fg1 })

  set("@markup.quote", { fg = c.fg2, italic = true })
  set("@markup.math", { fg = c.purple })

  set("@markup.list", { fg = c.pink, bold = true })
  set("@markup.list.checked", { fg = c.cyan_neon, bold = true })
  set("@markup.list.unchecked", { fg = c.fg2 })

  set("@constant.html", { fg = c.lime_import, bold = true })
  set("@tag", { fg = c.red_neon, bold = true })
  set("@tag.delimiter", { fg = c.bg4 })
  set("@tag.attribute", { fg = c.purple, bold = true })

  set("@tag.css", { fg = c.red_neon, bold = true })
  set("@type.css", { fg = c.mint_class, bold = true })
  set("@property.css", { fg = c.purple, bold = true })
  set("@tag.attribute.css", { fg = c.purple, bold = true })
  set("@constant.css", { fg = c.yellow, bold = true })

  -- INTERFAZ INTERNA
  set("MatchParen", { fg = c.white, bg = c.deep, bold = true })
  set("Todo", { fg = c.bg0, bg = c.yellow, bold = true })
  set("Debug", { fg = c.error2, bold = true })

  -- RAINBOW DELIMITERS
  set("RainbowDelimiterRed", { fg = c.cyan_neon })
  set("RainbowDelimiterYellow", { fg = c.yellow })
  set("RainbowDelimiterBlue", { fg = c.cyan_soft })
  set("RainbowDelimiterOrange", { fg = c.orange })
  set("RainbowDelimiterGreen", { fg = c.mint_class })
  set("RainbowDelimiterViolet", { fg = c.lime_import })
  set("RainbowDelimiterCyan", { fg = c.teal_alt })

  -- RENDER MARKDOWN
  set("RenderMarkdownH1", { fg = c.cyan1, bold = true })
  set("RenderMarkdownH2", { fg = c.cyan2, bold = true })
  set("RenderMarkdownH3", { fg = c.ice, bold = true })
  set("RenderMarkdownH4", { fg = c.teal, bold = true })
  set("RenderMarkdownH5", { fg = c.blue, bold = true })
  set("RenderMarkdownH6", { fg = c.purple, bold = true })
  set("RenderMarkdownH1Bg", { fg = c.cyan1, bg = "#0b1f28", bold = true })
  set("RenderMarkdownH2Bg", { fg = c.cyan2, bg = c.bg1, bold = true })
  set("RenderMarkdownBullet", { fg = c.cyan1, bold = true })
  set("RenderMarkdownNumber", { fg = c.blue, bold = true })
  set("RenderMarkdownTableHead", { fg = c.purple, bold = true })
  set("RenderMarkdownTableRow", { fg = c.fg0 })
  set("RenderMarkdownTableFill", { fg = c.fg2 })
  set("RenderMarkdownTableBorder", { fg = c.border })
  set("RenderMarkdownCode", { bg = c.bg1 })
  set("RenderMarkdownCodeInline", { fg = c.cyan1, bg = c.bg2 })
  set("RenderMarkdownQuote", { fg = c.fg2, bg = c.bg1 })
  set("RenderMarkdownRule", { fg = c.border })
  set("RenderMarkdownInfo", { fg = c.blue, bold = true })
  set("RenderMarkdownSuccess", { fg = c.teal, bold = true })
  set("RenderMarkdownError", { fg = c.cyan1, bold = true })
  set("RenderMarkdownWarn", { fg = c.warn2, bold = true })
end

return M
