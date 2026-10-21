-- =========================================================
-- AstroInit: scaffolding de proyectos Astro (:AstroInit)
-- =========================================================
-- Patrón de UI: JavaInit (vim.ui.input encadenados + validación).
-- Con internet: `npm create astro@latest` como job async (template
-- minimal, sin git, sin preguntas). Sin internet (o si npm/create
-- fallan): scaffold local mínimo y aviso de ejecutar `npm install`
-- cuando haya red.

local M = {}

-- Mismo criterio que JavaInit: letras, números, guiones y guiones bajos
local function is_valid_name(name)
  return name ~= nil and name:match("^[a-zA-Z0-9_%-]+$") ~= nil
end

-- Abrir el proyecto resultante (común a ambos caminos)
local function finish(full_path)
  vim.cmd("cd " .. vim.fn.fnameescape(full_path))
  local index = full_path .. "/src/pages/index.astro"
  if vim.fn.filereadable(index) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(index))
  end
  vim.notify("Proyecto Astro creado en " .. full_path, vim.log.levels.INFO, { title = "AstroInit" })
end

-- Scaffold local para cuando no hay red (sin node_modules; el usuario
-- ejecuta `npm install` cuando vuelva la internet)
function M.scaffold_local(full_path, name)
  vim.fn.mkdir(full_path .. "/src/pages", "p")

  local files = {
    ["package.json"] = string.format(
      [[{
  "name": "%s",
  "type": "module",
  "version": "0.0.1",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^7.4.0"
  }
}
]],
      name
    ),
    ["astro.config.mjs"] = [[import { defineConfig } from 'astro/config';

export default defineConfig({});
]],
    ["tsconfig.json"] = [[{
  "extends": "astro/tsconfigs/strict"
}
]],
    ["src/pages/index.astro"] = [[---
// Bienvenido a Astro. Editá esta página para empezar.
---

<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Astro</title>
  </head>
  <body>
    <h1>¡Hola, Astro!</h1>
  </body>
</html>
]],
  }

  for rel, content in pairs(files) do
    local path = full_path .. "/" .. rel
    local fd = io.open(path, "w")
    if fd then
      fd:write(content)
      fd:close()
    end
  end
end

-- Camino con internet: create-astro oficial, todo no interactivo
function M.scaffold_online(target_dir, name, full_path)
  vim.notify("Creando proyecto Astro con create-astro…", vim.log.levels.INFO, { title = "AstroInit" })
  local cmd = string.format("npm create astro@latest %s -- --template minimal --no-git --yes", vim.fn.shellescape(name))

  vim.fn.jobstart(cmd, {
    cwd = target_dir,
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        finish(full_path)
      else
        vim.notify(
          "create-astro falló (exit " .. code .. "); usando template local.",
          vim.log.levels.WARN,
          { title = "AstroInit" }
        )
        M.scaffold_local(full_path, name)
        finish(full_path)
      end
    end,
  })
end

function M.create_project()
  vim.ui.input({ prompt = "Target Directory: ", default = vim.fn.getcwd() }, function(target_dir)
    if not target_dir or target_dir == "" then
      return
    end

    vim.ui.input({ prompt = "Project Name: ", default = "demo" }, function(name)
      if not name or name == "" then
        return
      end
      if not is_valid_name(name) then
        vim.notify("Nombre inválido: solo letras, números, guiones y guiones bajos.", vim.log.levels.ERROR)
        return M.create_project() -- reintenta
      end

      local full_path = target_dir .. "/" .. name
      if vim.fn.isdirectory(full_path) == 1 then
        vim.notify("El directorio ya existe: " .. full_path, vim.log.levels.ERROR)
        return M.create_project() -- reintenta
      end

      -- Decidir camino: npm disponible + red alcanzable → create-astro;
      -- en cualquier otro caso → scaffold local
      local has_npm = vim.fn.executable("npm") == 1
      local has_net = false
      if has_npm then
        vim.fn.system("curl -sI --max-time 3 -o /dev/null https://registry.npmjs.org")
        has_net = vim.v.shell_error == 0
      end

      if has_net then
        M.scaffold_online(target_dir, name, full_path)
      else
        if not has_npm then
          vim.notify("npm no encontrado; usando template local.", vim.log.levels.WARN, { title = "AstroInit" })
        else
          vim.notify("Sin internet; usando template local.", vim.log.levels.WARN, { title = "AstroInit" })
        end
        M.scaffold_local(full_path, name)
        finish(full_path)
      end
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("AstroInit", M.create_project, { desc = "Initialize Astro Project" })
end

M.setup()

return M
