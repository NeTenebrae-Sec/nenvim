-- =========================================================
-- lua/plugins/snacks.lua
-- Configuración modular, rápida y optimizada de snacks.nvim
-- =========================================================
local status, snacks = pcall(require, "snacks")
if not status then
  return
end
Snacks = snacks

-----------------------------------------------------------
-- OPCIONES DE HEADER / ASCII ART PARA EL DASHBOARD
-----------------------------------------------------------
local header_1 = [[
 ███▄    █ ▓█████   ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓ 
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒ 
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░ 
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██  
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒ 
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░ 
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░ 
    ░   ░ ░    ░    ░ ░ ░ ▒        ░░   ▒ ░░      ░   
          ░    ░  ░    ░ ░         ░   ░          ░   
                                   ░                  
]]

local header_2 = [[⠀⠀⠀⠀
⣿⣿⣿⣿⣇⢻⡇⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠾⠿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣄⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠈⠠⠀⠀⠀⠀⠀⠀⠡⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠱⣄⠀⠀⠀⠀⠀⠘⠆⠀⠈⢿⣦⠀⠀⠠⠀⠀⠀⠀⠀⢰⣶⣶⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⡶⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡄⠀⠀⠀⠀⠀⠀⠘⣦⣀⠀⠀⠀⢠⣀⠀⠀⠈⠳⠦⠀⠀⠀⠀⠀⠀⠐⠀⢻⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⢟⡿⠃⠜⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣇⠀⠀⠀⣷⣄⠀⠀⠈⠛⢷⣶⣤⡄⠙⠳⠦⣤⡀⠈⠀⠀⠀⡀⠸⣤⣄⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⠟⢠⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠈⠻⠷⠆⢰⣿⣿⣷⣤⡀⠈⠻⣿⣿⣿⣦⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠠⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⡿⢃⣴⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⢶⣶⣄⠄⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⠉⠀⢀⣠⣴⣶⣶⣶⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⠋⣰⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣦⡀⢀⣾⣄⠠⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣡⣿⣿⠃⠀⠀⠀⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⢰⡿⢋⣴⣿⣿⣿⣿⣦⣤⡹⣿⣿⣿⣿⣿⣿⣿⣿⣧⡁⠀⠈⠉⠛⠛⠿⣿⣷⣀⡐⠠⠷⣼⠂⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣉⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡛⢿⣿⣿⣿⣿⣿⣿⣿⣷⣴⣆⣠⡀⠀⠀⠉⠛⠛⠛⠋⠉⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⡡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⢌⡛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣦⣄⣀⣀⡠⠀⡤⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡻⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⡿⠋⢀⣤⣄⣠⣴⠟⢁⡴⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡛⢿⣿⣿⣿⣴⣿⣿⣿⠟⣁⠔⣫⣴⠀⡀⠀⠀⠀⠀⠀
⠀⠀⠀⡠⠀⠀⡐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡉⢿⡿⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣭⣀⡂⠉⢛⠻⠿⢋⠥⢊⣡⣾⣿⣷⡄⠀⢠⠀⠀⠀⠀
⠀⠀⡔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣆⣻⣿⣷⣬⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣌⣒⠂⠭⠍⠛⠻⢿⠃⠀⣸⠀⠀⠀⠀]]

-- 👉 Elige aquí la opción activa (1 o 2)
local opcion_header = 1

local headers = {
  [1] = header_1,
  [2] = header_2,
}

snacks.setup({
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  toggle = { enabled = true },

  image = {
    enabled = true,
    doc = {
      inline = false, -- Usamos solo ventana flotante
      float = true,
      max_width = 40, -- Ajustamos a un tamaño más pequeño y elegante
      max_height = 20,
    },
    env = {
      SNACKS_KITTY = true, -- Forzar renderizado consistente en tu terminal Kitty
    },
  },

  styles = {
    snacks_image = {
      relative = "cursor", -- Sigue la posición de tu cursor
      anchor = "NW", -- Anclamos la esquina superior izquierda (North-West) de la imagen
      row = 0, -- Alineado exactamente con la misma altura de tu cursor
      col = 50, -- Desplazado 4 caracteres a la derecha para no tapar lo que escribes
      border = "rounded",
      focusable = false, -- No roba el foco del teclado al aparecer
      zindex = 50, -- Se dibuja siempre por encima de cualquier otro panel
    },
  },

  -- ⌨️ INTERFAZ DE ENTRADA Y NOTIFICACIONES
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
    style = "fancy",
  },

  -- 󰠚 ANIMACIONES (Scroll y Aturdimiento/Dim)
  scroll = { enabled = true },

  dim = {
    enabled = true,
    scope = {
      min_size = 5,
      max_size = 20,
      siblings = true,
    },
    animate = { enabled = true },
  },

  --  GUÍAS VISUALES (Indentación y Áreas de Código)
  indent = { enabled = true },

  scope = {
    enabled = true,
    cursor = true,
    edge = true,
    min_size = 2,
    max_size = 20,
    treesitter = {
      enabled = true,
      injections = true,
      blocks = {
        enabled = true,
        "function_declaration",
        "function_definition",
        "method_declaration",
        "method_definition",
      },
    },
  },

  -- 🔤 RESALTADO DE PALABRAS REPETIDAS
  words = {
    enabled = true,
    debounce = 300, -- Tiempo de espera sensato
    notify_jump = false,
    -- Forzamos a que solo actúe en modo Normal, nunca editando
    modes = { "n" },
  },

  -- 📝 BLOC DE NOTAS RÁPIDAS (Scratchpads)
  scratch = {
    enabled = true,
    name = "notes",
    ft = "markdown",
    root = vim.fn.stdpath("data") .. "/scratch",
    autowrite = true,
    filekey = {
      cwd = true,
      branch = false,
      count = true,
    },
    win = { style = "scratch" },
  },

  -- 🔍 BUSCADOR (Picker) Y EXPLORADOR DE ARCHIVOS
  picker = {
    enabled = true,
    win = {
      input = {
        keys = {
          ["<c-p>"] = { "toggle_preview", mode = { "n", "i" } },
        },
      },
    },
    sources = {
      explorer = {
        win = {
          wo = {
            modifiable = true,
            readonly = false,
          },
        },
      },
    },
  },

  explorer = {
    enabled = true,
    replace_netrw = true,
    git_status = true,
  },

  -- 󰞷 TERMINAL FLOTANTE INTEGRADA
  terminal = {
    enabled = true,
    win = {
      style = "float",
      border = "rounded",
      keys = { ["<esc>"] = "hide" },
      wo = {
        statusline = "",
        winbar = "",
        number = false,
        relativenumber = false,
        signcolumn = "no",
      },
    },
  },

  -- ⢵ COLUMNA DE ESTADO NATIVA
  statuscolumn = {
    enabled = true,
    left = { "mark", "sign" },
    right = { "fold", "git" },
  },

  --  INTEGRACIÓN DE LAZYGIT
  lazygit = {
    enabled = true,
    config = {
      ui = { border = "rounded" },
    },
    win = {
      position = "float",
      backdrop = 60,
    },
  },

  -- 🧘 MODO ZEN
  zen = {
    enabled = true,
    toggles = {
      dim = false,
      git_signs = false,
      mini_diff_signs = false,
      diagnostics = false,
      inlay_hints = false,
    },
    show = {
      statusline = false,
      tabline = false,
    },
    win = {
      style = "none",
      backdrop = {
        transparent = false,
        blend = 85,
      },
      wo = {
        number = true,
        relativenumber = false,
        signcolumn = "yes",
        foldcolumn = "0",
      },
    },
  },

  -- 📊 PANTALLA DE INICIO (Dashboard)
  dashboard = {
    enabled = true,
    init = function()
      vim.opt.laststatus = 3
    end,
    sections = {
      { section = "header", padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
    },
    preset = {
      header = headers[opcion_header],
      keys = {
        {
          icon = " ",
          key = "f",
          desc = "Find File",
          action = function()
            Snacks.picker.files()
          end,
        },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        {
          icon = " ",
          key = "g",
          desc = "Find Text",
          action = function()
            Snacks.picker.grep()
          end,
        },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
})
