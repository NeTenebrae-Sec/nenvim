# Spec Global — nenvim

> Spec maestra del proyecto. Toda spec de tarea debe alinearse con lo
> definido aquí. Si hay conflicto, la spec de la tarea define el detalle
> y esta spec define el objetivo, el flujo y los estándares.

## 1. Objetivo del proyecto

Convertir **nenvim** en un entorno de desarrollo fullstack completo.

**Estado actual:** integración consolidada para **Java** (jdtls, Spring Boot,
debugger, dependencias) y parcial para **Astro** y el stack web.

**Objetivo prioritario:** lograr compatibilidad completa y consistente de:

- **LSP** (diagnósticos, navegación, renombrado, code actions)
- **Linter** (diagnósticos estáticos sin duplicar al LSP)
- **Formatter** (conform + configs del proyecto)
- **CMP** (completion limpia, sin fuentes duplicadas, snippets)
- **Creación de archivos** (snippets/scaffolding donde aporte)

Para: **Astro → Node.js → React → NextJS → TypeScript** y las bases ya
presentes (HTML, CSS, JSON, YAML, Lua, Markdown, Python, C).

## 2. Stack bajo revisión

| Componente | Implementación actual |
| --- | --- |
| Neovim | 0.12.6 (`vim.lsp.config` / `vim.lsp.enable` nativo) |
| Plugins | `vim.pack` (nativo, start/ + opt/) |
| Gestión de binarios | Mason + mason-tool-installer (`lua/plugins/lsp/mason.lua`) |
| LSP core | `lua/plugins/lsp/init.lua` + `servers/` modular |
| Linters | nvim-lint (`lua/plugins/lsp/linter/`) |
| Formatters | conform (`lua/plugins/lsp/formatters/`) |
| Completion | nvim-cmp + LuaSnip + friendly-snippets (`lua/plugins/lsp/cmp/`) |
| Lenguajes embebidos | otter.nvim (`lua/plugins/lsp/otter.lua`) |
| Temas | `lua/themes/` (dark_cyan modular, dark_red) |

## 3. Flujo de desarrollo (Spec Driven Development)

1. **Definir la spec de tarea** en `specs/tasks/NNN-nombre.md` usando
   `specs/templates/TASK.md`. Los criterios de aceptación deben ser
   **verificables en vivo** (qué cliente está adjunto, qué diagnóstico
   aparece, qué output da el formatter), no opiniones.
2. **Verificar prerequisitos**: nvim-mcp conectado (ver §5), instancia
   interactiva de nvim con socket, proyecto de prueba disponible.
3. **Implementar** los cambios en la config respetando los estándares (§4).
4. **Verificar en vivo**: con nvim abierto en el archivo/proyecto relevante,
   el agente usa nvim-mcp para observar la realidad (clientes adjuntos,
   capabilities, diagnósticos, formato aplicado, highlights). Cada criterio
   se marca `[x]` **solo con evidencia observada**, anotada en la spec.
5. **Registrar resultados** en la spec: estado de cada criterio, decisiones
   tomadas (incluidas las de "no requerido" con su justificación) y
   pendientes/riesgos descubiertos.
6. **Commit** con mensaje `spec(nnn): ...` o `feat(nnn): ...` según corresponda.

**Regla de oro:** no declarar algo "funcionando" sin haberlo visto funcionar
en una sesión real. Si no se pudo verificar, el criterio queda `[~]` (parcial)
con nota de qué faltó.

## 4. Estándares de código

- **Requisitos mínimos por lenguaje (R1–R5)**: todo lenguaje que se
  integre debe cumplir, verificado en vivo:
  - **R1** Live-server: `<leader>us` sirve el proyecto (detectar el dev
    server propio del framework; p. ej. `astro dev`, no `vite`).
  - **R2** DAP/runner: módulo en `lua/plugins/lsp/dap/<ft>.lua` con
    `run()` (detección→menú→Kitty, patrón `java.lua`) y `setup()`.
    **Opcional en frontend** (JS/TS de navegador, p. ej. Astro/React):
    el `run()` (dev server, build, check…) sí es obligatorio; el adapter
    de depuración del navegador (p. ej. `pwa-chrome` + js-debug) solo se
    registra si el usuario lo pide explícitamente — no por defecto.
  - **R3** Linter asignado (usando la toolchain del proyecto).
  - **R4** LSP asignado (diagnósticos, hover, gd, completion, rename).
  - **R5** CMP completion cross-file (imports→símbolos de otros archivos,
    `gd`/hover, fuente `path`).
- **Modularidad por lenguaje/área**: LSP por servidor en `servers/`,
  linters en `linter/`, formatters en `formatters/`, DAP en `dap/`. Un
  archivo por lenguaje.
- **Defensivo**: toda integración externa con `pcall` y retorno temprano si
  falta la dependencia (patrón usado en toda la config).
- **Sin duplicates**: antes de agregar un linter/server, verificar que no
  duplica diagnósticos ya cubiertos por otro componente.
- **Configs locales primero**: si el proyecto trae su config (prettierrc,
  eslint, tsconfig), respetarla; fallbacks solo como último recurso.
- **Estilo**: comentarios en español, nombres en inglés, secciones con
  encabezado `=====` como en los archivos existentes.
- **Compatibilidad**: Neovim 0.12+ (APIs nuevas: `vim.lsp.config`,
  `vim.lsp.enable`, `vim.lsp/inlay_hint`, etc.).

## 5. Infraestructura de verificación (MCP)

- **nvim-mcp** (server MCP vía `uvx nvim-mcp`) conecta al agente con la
  instancia interactiva de nvim por msgpack-RPC. Config del server:
  `opencode.jsonc` (este proyecto). Reglas de uso del agente: `AGENTS.md`.
- **Socket**: la instancia interactiva inicia un servidor RPC con nombre
  fijo (`$XDG_RUNTIME_DIR/nvim-mcp.sock`) vía `lua/config/rpc.lua`.
  `NVIM_ADDRESS` en la config del MCP apunta directo ahí (evita elegir la
  instancia `--embed` que OpenCode lanza para su propio LSP).
- El agente **no** debe escribir en discos archivos abiertos en buffers del
  usuario (usar herramientas de buffer del MCP → undo inmediato).

## 6. Roadmap de tareas

| ID | Tarea | Estado |
| --- | --- | --- |
| 000 | Setup MCP (nvim-mcp + socket + reglas de agente) | ✅ Completada |
| 001 | Astro al 100% | 🚧 Casi completa (ver `specs/tasks/001-astro-100.md` §I) |
| 002 | Toolchain: registro único `filetype → {lsp,lint,format,cmp}` + guard `LspAttach` | ⬜ Propuesta (siguiente) |
| 003 | Rendimiento (línea base: 4,6 s arranque / 1,06 s edit HTML 12k → objetivo <2 s / <400 ms) | ✅ Completada (ver `specs/tasks/003-rendimiento.md`) |
| 004 | Node.js / TypeScript | ⬜ Pendiente |
| 005 | React / JSX | ⬜ Pendiente |
| 006 | NextJS | ⬜ Pendiente |
| 007 | Bases (HTML/CSS/JSON/YAML/Lua/MD) | ⬜ Pendiente |
| 008 | Refinamientos globales (flood html-css, stack TS único, semantic tokens, tailwind/html-css sobrantes) | ⬜ Pendiente |

> La tarea **002 (toolchain)** es el marco que absorbe las excepciones
> actuales (plugins que se wiring solos: `html-css-lsp`, otter) y hace que
> R3/R4/R5 se declaren por ficha de lenguaje en vez de a mano.
> La tarea **008** concentra los problemas transversales del diagnóstico
> inicial (flood `html-css-lsp`, SIGTERM de TSServer, semantic tokens
> off, clientes `tailwindcss`/`html-css` que se adjuntan a proyectos que
> no los usan).

## 7. Convenciones de specs

- Nombre: `NNN-nomo-en-minusculas.md` con zero-padding de 3 dígitos.
- Estados de criterio: `[ ]` pendiente · `[~]` parcial · `[x]` verificado
  con evidencia · `[-]` no requerido (con justificación).
- Estado de tarea: ⬜ pendiente · 🚧 en progreso · ✅ completada.
- Las specs viven en el repo (`git add` incluye siempre specs/ al commit).
