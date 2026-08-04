-- =========================================================
-- lua/plugins/mini.lua
-- =========================================================

local modules = {
    surround = {
        mappings = {
            add = "Sa",
            delete = "Sd",
            replace = "Sr",
            find = "Sf",
            find_left = "SF",
            highlight = "Sh",
            update_n_lines = "Sn",
        },
    },
    ai = {},
    comment = {},
    pairs = {},
    splitjoin = {},
    bufremove = {},
    align = {},

    move = {
        options = {
            reindent_linewise = true,
        },
    },

    input = {
        window = {
            config = { border = "rounded" },
        },
    },
}

for name, config in pairs(modules) do
    local ok, module = pcall(require, "mini." .. name)
    if ok then
        local opts = type(config) == "function" and config() or config
        module.setup(opts)
    end
end
