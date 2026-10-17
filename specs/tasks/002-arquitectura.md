# Tarea 002 — Arquitectura por lenguaje (motores + fichas)

- **Estado:** 🚧 Spec aprobada (código pendiente)
- **Depende de:** 000 (MCP para verificación en vivo), 003 (línea base anti-regresión)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Reemplazar la organización "por tipo de componente" (`servers/`, `linter/`,
`formatters/`, `dap/`, listas hardcodeadas) por **motores autónomos + fichas
por lenguaje**, con un requisito transversal de robustez apta para
distribución comunitaria:

- **Motores** (`lua/core/`): infraestructura viva, como ya lo es LSP hoy.
  Cada motor "sabe hacer su trabajo" solo (autocmds, listeners, machinery)
  y su única fuente de *qué* aplicar es leer `languages/`.
- **Fichas** (`lua/languages/<lengua>/init.lua`): datos puros. Cero
  requires entre fichas. Borrar una carpeta = quitar un lenguaje de todo.
- Entre lenguajes, todo reacciona igual: misma máquina, distintos datos.

## R0 — Arranque en máquina vacía (requisito transversal)

> nvim debe abrir en un sistema sin nada instalado (0 plugins, 0 binarios
> LSP, sin npm/node, sin internet) **sin un solo error**, degradando cada
> función ausente con un notify discreto, y auto-actualizándose a demanda.

- Sin plugins/internet: carga base (options/keymaps/rpc) funciona;
  `load_all` con `pcall` → fallo = notify, nunca crash.
- Sin binarios (mason vacío): el motor omite ese registro; el lenguaje
  degrada a "sin LSP/format", no a error. `core/mason` instala **a demanda**
  (al abrir un archivo del lenguaje) o en background; nunca bloquea.
- Sin node/npm: fichas node-based se registran parcialmente (treesitter sí,
  LSP no).
- `:checkhealth nete` (F5): tabla lenguaje × (plugin, binario, estado).
- Verificado en cada fase con el **protocolo máquina vacía**:
  `XDG_DATA_HOME=/tmp/fresh XDG_STATE_HOME=/tmp/fresh XDG_CACHE_HOME=/tmp/fresh
  nvim --headless -c 'qa!'` → 0 errores.

## Principios de diseño

1. **Fichas = datos**: solo tablas declarativas (+ funciones locales
   propias del lenguaje, p. ej. AstroInit o el árbol java). Ninguna ficha
   hace `require` de otra ficha ni de `core/`.
2. **Dependencias**: `core/*` → solo `require("languages")` (lista de
   datos, cacheada). `languages/*` → cero requirements externos. El
   scanner `languages/init.lua` es el único que lee carpetas.
3. **Idempotencia por nombre**: si dos fichas declaran el mismo server
   (`vtsls`), se define una vez — primera definición gana. Sin merge mágico.
4. **Tools por string**: las fichas nombran binarios (`"prettier"`,
   `"astro-ls"`); `core/mason` los resuelve (PATH → mason → local) e
   instala los declarados, lazy y no bloqueante.
5. **Defensivo por diseño** (R0): todo registro de motor pasa por
   comprobación de existencia; ausencia = skip + notify discreto.
6. **Borrar > migrar** no aplica: **decidido migrar todo** (svelte/vue/json
   incluidos).
7. **Anti-regresión 003**: arranque y edición HTML medidos igual que en
   `specs/tasks/003-rendimiento.md`.

## Layout

```
lua/config/       options, keymaps/, rpc, patches, vimpack (bootstrap + loader)
lua/core/         lsp/ (init, diagnostics, guards)  format/  lint/
                  dap/ (init, runner, ui)  cmp/  treesitter/  mason/
lua/languages/    init.lua (scanner)  astro/  node-ts/  react/  html-css/
                  java/  lua/  python/  c/  bash/  markdown/  sql/
                  svelte/  vue/  json/
lua/ui/           lualine, bufferline, gitsigns, noice, devicons, rainbow,
                  smear_cursor, render-markdown, ccc  (tema = default del
                  terminal; decidido: sin módulo theme)
lua/plugins/      live-server, trident/, nepost/, snacks, flash, mini,
                  multi_cursor, perf_monitor  (features sueltas; AstroInit
                  migra a languages/astro/)
snippets/  specs/  AGENTS.md
```

**Reglas de dependencia**: `config/` → nada; `core/*` → `languages`;
`languages/*` → nada; `ui/`/`plugins/` → `core/*` (pcall), nunca al revés.

## Schema de ficha

| Campo | Tipo | Registra en |
| --- | --- | --- |
| `filetypes` | string[] | todos los motores |
| `root_markers` | string[] | lsp, dap runner |
| `lsp` | string[] o {name, config, guard?} | core/lsp |
| `lint` | tabla<ft, linter[]> | core/lint |
| `format` | tabla<ft, orden[]> | core/format |
| `parsers` | string[] | core/treesitter |
| `cmp` | {sources extras por ft} | core/cmp |
| `dap` | {adapters?, configurations?}? | core/dap (frontend vacío: GLOBAL §4 R2) |
| `tools` | string[] | core/mason |
| `init_cmd` | string? | scaffolding (AstroInit, JavaInit) |
| `guard` | function(buf)? | attach condicional |

## Motores: qué posee cada uno

| Motor | Comportamiento (autónomo) | Datos desde fichas |
| --- | --- | --- |
| `core/lsp` | capabilities, diagnósticos globales, guards LspAttach | servers + guards |
| `core/format` | conform setup, format_on_save | `format` |
| `core/lint` | autocmd → try_lint | `lint` |
| `core/dap` | signs, dapui, listeners, runner `<leader>dr` | `dap` |
| `core/cmp` | UI, performance, fuentes globales | `cmp` (extras por ft) |
| `core/treesitter` | install machinery, highlight, indent | `parsers` |
| `core/mason` | instalación lazy de tools declarados | `tools` |

API pública de cada motor: `setup()` + `register(datos)`.

## Fases de implementación

- **F0 Motores**: `core/*` (mecánica movida de `plugins/lsp/*` con
  comportamiento idéntico; registro vía `register()`), scanner
  `languages/init.lua` (vacío al inicio). Los módulos viejos se vuelven
  delgados: cargan sus datos actuales y los pasan por `register()`.
  Verificación: paridad total + protocolo máquina vacía.
- **F1 Piloto astro**: ficha completa (lsp/lint/format/parsers/cmp/
  tools/init_cmd + AstroInit). DoD astro en vivo.
- **F2 Resto de fichas**: node-ts, react, html-css, lua, python, c,
  markdown, sql, bash, java, svelte, vue, json — absorbiendo datos de
  `servers/`, `linter/`, `formatters/`, `dap/<lang>`. Al final: borrar
  directorios vacíos. GLOBAL §4 actualizado.
- **F3 Cero attaches rogue**: guards de proyecto (tailwind, html-css/cssls,
  vtsls).
- **F4 CMP cross-file**: fuentes por ficha; auditoría astro + TS/TSX.
- **F5 DoD + health**: tabla "lenguaje completado" en GLOBAL §4;
  `:checkhealth nete`; roadmap 002 ✅.

## Criterios de aceptación

- [ ] `grep -r 'require' lua/languages/` → 0 entre fichas (salvo scanner y
      árbol interno java).
- [ ] Motores funcionan solo con fichas; borrar una ficha no rompe motores.
- [ ] Protocolo máquina vacía: 0 errores en nvim headless con XDG vacío.
- [ ] neteumbra `.astro`: clientes = `astro` + emmet; lint/format/snippets/
      `<leader>us`/CMP idénticos a hoy.
- [ ] Proyecto con tailwind real: tailwind activo solo ahí.
- [ ] flood `html-css-lsp` ausente de lsp.log.
- [ ] R5 cross-file verificado en astro y TS/TSX.
- [ ] Sin regresión 003.
- [ ] GLOBAL §4 actualizado; roadmap 002 ✅.

## Plan de verificación

Cada fase: paridad en vivo (MCP) + auditoría CLI↔nvim (estilo 001 §J) +
protocolo máquina vacía + métricas 003. Rollback: directorios viejos se
eliminan solo al final de F2.

## Riesgos y notas

- Movimiento grande de maquinaria → comportamiento idéntico verificado
  fase a fase; fichas absorben datos gradualmente.
- Tema: default del terminal (decidido). svelte/vue/json: migrar
  (decidido).
- Buffers del usuario nunca se tocan (AGENTS.md). Commits por fase
  (`feat(002): ...`), GPG operativo.
