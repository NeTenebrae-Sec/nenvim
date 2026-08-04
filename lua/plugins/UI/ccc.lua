local ok, ccc = pcall(require, "ccc")
if not ok then
    return
end

vim.opt.termguicolors = true

ccc.setup({
    highlighter = {
        auto_enable = true,
        lsp = true,
    },
    inputs = {
        ccc.input.rgb,
        ccc.input.hsl,
    },
    outputs = {
        ccc.output.hex,
        ccc.output.css_rgb,
        ccc.output.css_hsl,
    },
    pickers = {
        ccc.picker.hex,
        ccc.picker.css_rgb,
        ccc.picker.css_hsl,
    },
})

vim.keymap.set("n", "gC", "<cmd>CccPick<CR>", { desc = "Selector de color" })
