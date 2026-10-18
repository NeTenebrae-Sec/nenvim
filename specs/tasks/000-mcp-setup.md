# Tarea 000 — Setup MCP (nvim-mcp)

- **Estado:** 🚧 En progreso (infra lista; falta prueba de conexión con nvim abierto)
- **Depende de:** ninguna
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Que el agente pueda ver lo que el usuario ve en nvim (buffers, clientes
LSP, diagnósticos, highlights) mediante nvim-mcp, como requisito de
verificación de todas las tareas siguientes.

## Alcance

- Server MCP `nvim-mcp` registrado en la config de OpenCode de este proyecto.
- Socket RPC con nombre fijo para la instancia interactiva de nvim.
- Reglas de agente (`AGENTS.md`) para uso correcto de las herramientas.

Fuera de alcance: mcphub u otros plugins de nvim (nvim-mcp no requiere
plugins).

## Criterios de aceptación

### A. Server MCP

- [x] `opencode.jsonc` (proyecto) declara `nvim-mcp` con `uvx nvim-mcp` —
      _evidencia: archivo creado con server `nvim-mcp`, type local._
- [x] La config global `~/.config/opencode/opencode.jsonc` no se modificó
      (playwright intacto) — _evidencia: solo lectura de esa.config._
- [x] `opencode mcp list` muestra `nvim-mcp` — _evidencia: salida real
      `✓ nvim-mcp connected` (2026-10-17), junto a `✓ playwright connected`
      intacto._

### B. Socket de nvim

- [x] `lua/config/rpc.lua` crea un socket con nombre fijo
      (`$XDG_RUNTIME_DIR/nvim-mcp.sock`) al arrancar nvim, sin romper
      instancias que ya tengan socket — _evidencia: archivo creado con
      serverstart condicional + autocmd VimEnter._
- [x] `init.lua` carga `config.rpc` — _evidencia: require agregado._
- [x] `lua/config/rpc.lua` carga sin errores (verificado en nvim headless:
      `rpc.lua OK`) — _evidencia: test headless 2026-10-17._
- [x] `init.lua` carga `config.rpc` (parse OK) — _evidencia: test headless._
- [x] **Usuario:** abrir nvim y confirmar conexión — _2026-10-17:
      instancia viva conectada vía MCP — `get_state_brief`/`get_state`
      devuelven la sesión real del usuario (cwd neteumbra, buffer
      `src/pages/404.astro`, modo normal); lecturas operativas todo el
      día (socket en `$XDG_RUNTIME_DIR/nvim-mcp.sock`)._
- [x] Server MCP inmune a cortes de red — _2026-10-17: incidente real —
      DNS caído → `uvx nvim-mcp` no resolvía PyPI, el puente moría
      (exit 2) y opencode descartaba las tools nvim-mcp de la sesión.
      Fix: `command` → `["uvx", "--offline", "nvim-mcp"]` (caché local
      de uv, nvim-mcp 1.1.1, sin red). Evidencia: `uvx --offline
      nvim-mcp` exit 0 con red caída; `opencode mcp list` →
      `✓ nvim-mcp connected` + tools restauradas en la sesión._

### C. Reglas de agente

- [x] `AGENTS.md` en la raíz del proyecto con las reglas de nvim-mcp
      (basadas en AGENTS-EXAMPLE.md upstream, adaptadas al español) —
      _evidencia: archivo creado._

## Archivos a tocar

- `opencode.jsonc` — server MCP del proyecto (nuevo)
- `AGENTS.md` — reglas de agente (nuevo)
- `lua/config/rpc.lua` — socket RPC (nuevo)
- `init.lua` — require de rpc (edit)

## Plan de verificación

1. Cerrar y reabrir nvim → confirmar que `$XDG_RUNTIME_DIR/nvim-mcp.sock` existe.
2. Reiniciar la sesión de OpenCode → `/mcps` o `opencode mcp list` → `nvim-mcp connected`.
3. Pedir al agente: "¿qué archivo tengo abierto y qué diagnósticos hay?" — debe
   responder con datos reales del buffer.

## Riesgos y notas

- La instancia `nvim --embed` que OpenCode lanza para su propio LSP también
  expone socket (`nvim.<pid>.0`); por eso `NVIM_ADDRESS` fija la ruta y se
  evita la autodescubierta ambigua.
- `:h serverstart` en VimEnter es seguro: nvim permite múltiples servers por
  instancia; si el socket ya está en uso por otra instancia, se omite.
