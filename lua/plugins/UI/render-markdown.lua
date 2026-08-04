local ok, render_md = pcall(require, "render-markdown")
if not ok then
    return
end

render_md.setup({
    latex = {
        enabled = false,
    },
    anti_conceal = {
        enabled = true,
    },
    code = {
        sign = false,
        width = "block",
        right_pad = 4,
    },
    heading = {
        icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
    },
})
