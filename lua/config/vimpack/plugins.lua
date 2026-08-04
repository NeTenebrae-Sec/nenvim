-- ==========================================================================
-- vimpack: plugins.lua | ADD REPO PLUGINS HERE
-- -- ==========================================================================
local pack_path = vim.fn.stdpath("data") .. "/site/pack/plugins"

return {
  path = pack_path,
  list = {
    { url = "https://github.com/sphamba/smear-cursor.nvim", dest = "start/smear-cursor.nvim" },

    -- Treesitter & Context
    {
      url = "https://github.com/nvim-treesitter/nvim-treesitter",
      dest = "start/nvim-treesitter",
      build = "TSUpdate",
    },
    { url = "https://github.com/windwp/nvim-ts-autotag", dest = "start/nvim-ts-autotag" },
    { url = "https://github.com/nvim-treesitter/nvim-treesitter-context", dest = "start/nvim-treesitter-context" },
    { url = "https://github.com/hiphish/rainbow-delimiters.nvim", dest = "start/rainbow-delimiters.nvim" },

    { url = "https://github.com/folke/flash.nvim", dest = "start/flash.nvim" },

    -- UI Components
    { url = "https://github.com/nvim-tree/nvim-web-devicons", dest = "start/nvim-web-devicons" },
    { url = "https://github.com/lewis6991/gitsigns.nvim", dest = "start/gitsigns.nvim" },
    { url = "https://github.com/MunifTanjim/nui.nvim", dest = "start/nui.nvim" },
    { url = "https://github.com/MeanderingProgrammer/render-markdown.nvim", dest = "start/render-markdown.nvim" },
    { url = "https://github.com/nvim-lualine/lualine.nvim", dest = "start/lualine.nvim" },
    { url = "https://github.com/akinsho/bufferline.nvim", dest = "start/bufferline.nvim" },
    { url = "https://github.com/folke/noice.nvim", dest = "start/noice.nvim" },
    { url = "https://github.com/uga-rosa/ccc.nvim", dest = "start/ccc.nvim" },
    { url = "https://github.com/gorbit99/codewindow.nvim", dest = "start/codewindow.nvim" },

    { url = "https://github.com/echasnovski/mini.nvim", dest = "start/mini.nvim" },
    { url = "https://github.com/folke/snacks.nvim", dest = "start/snacks.nvim" },

    -- LSP / Tools Core
    { url = "https://github.com/hrsh7th/cmp-nvim-lsp", dest = "start/cmp-nvim-lsp" },
    { url = "https://github.com/neovim/nvim-lspconfig", dest = "start/nvim-lspconfig" },
    { url = "https://github.com/williamboman/mason.nvim", dest = "start/mason.nvim" },
    {
      url = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
      dest = "start/mason-tool-installer.nvim",
    },
    { url = "https://github.com/stevearc/conform.nvim", dest = "start/conform.nvim" },
    { url = "https://github.com/mfussenegger/nvim-lint", dest = "start/nvim-lint" },
    { url = "https://github.com/folke/lazydev.nvim", dest = "start/lazydev.nvim" },
    {
      url = "https://github.com/jmbuhr/otter.nvim",
      dest = "start/otter.nvim",
    },

    -- CSS/HTML Cross IntelliSense
    { url = "https://github.com/hrsh7th/nvim-cmp", dest = "start/nvim-cmp" },
    { url = "https://github.com/hrsh7th/cmp-buffer", dest = "start/cmp-buffer" },
    { url = "https://github.com/hrsh7th/cmp-path", dest = "start/cmp-path" },
    { url = "https://github.com/saadparwaiz1/cmp_luasnip", dest = "start/cmp_luasnip" },
    { url = "https://github.com/rafamadriz/friendly-snippets", dest = "start/friendly-snippets" },
    { url = "https://github.com/L3MON4D3/LuaSnip", dest = "start/LuaSnip" },
    { url = "https://github.com/mg979/vim-visual-multi", dest = "start/vim-visual-multi" },
    { url = "https://github.com/Jezda1337/nvim-html-css", dest = "start/nvim-html-css" },

    -- Debugging (DAP)
    { url = "https://github.com/mfussenegger/nvim-dap", dest = "start/nvim-dap" },
    { url = "https://github.com/rcarriga/nvim-dap-ui", dest = "start/nvim-dap-ui" },
    { url = "https://github.com/jay-babu/mason-nvim-dap.nvim", dest = "start/mason-nvim-dap.nvim" },
    { url = "https://github.com/mxsdev/nvim-dap-vscode-js", dest = "start/nvim-dap-vscode-js" },
    { url = "https://github.com/nvim-neotest/nvim-nio", dest = "start/nvim-nio" },
  },
}
