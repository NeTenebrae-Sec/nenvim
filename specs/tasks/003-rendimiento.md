# Tarea 003 — Rendimiento

- **Estado:** ✅ Completada (fixes de arranque y de HTML grande; queda
  documentado el hallazgo de prettier en archivos gigantes)
- **Depende de:** 000 (MCP para verificación en vivo)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Arranque de nvim < 2 s y edición de un HTML de 12k líneas < 400 ms.
La línea base original del roadmap (4,6 s arranque / 1,06 s edit) no tenía
metodología documentada; aquí se (re)define la medida y se (re)midieron
antes y después con la misma metodología.

## Metodología

- Sistema real del usuario (Firefox/opencode abiertos; load 4–10; kswapd0
  activo en momentos de presión de memoria). Los números son el **mínimo de
  2–3 corridas** por métrica.
- Probes con `nvim --headless` + `vim.uv.hrtime()`; apertura total con la
  marca `--- NVIM STARTED ---` de `--startuptime`.
- **BufEnter re-ejecución**: `nvim_exec_autocmds("BufEnter", {buffer=0})`
  en una sesión ya arrancada (simula re-entrar al buffer).
- **Guardado**: `:silent write` tras modificar una línea (corre conform/
  prettier + BufWritePre reales).
- **Edición**: `:edit` de un archivo en una nvim ya arrancada (abrir desde
  picker/terminal con el editor corriendo).
- ⚠️ Cada apertura de HTML lanza `markuplint` (linter LSP de la config del
  usuario, ~55 % CPU por instancia). Los probes headless lo dejan huérfano
  al salir y contamina TODAS las mediciones siguientes (se vio: edit 198 ms
  → 983 ms según cuántos huérfanos haya). **Entre tandas: `pkill
  markuplint`** (verificado: el nvim vivo del usuario no tenía HTML abierto,
  todos los huérfanos eran de probes).
- Archivo sintético: `/tmp/opencode/big.html`, 12.502 líneas / 1,33 MB
  (`<section class=... id=...>…`), regenerable con awk.

## Resultados (antes → después)

| Métrica | Antes (Fase C) | Después | Objetivo | Cumple |
| --- | --- | --- | --- | --- |
| Arranque nvim + HTML 12k (`--startuptime`) | 1.808 ms | **626 ms** (626/1.185/1.318) | < 2 s | ✅ |
| Edición: `:edit` 12k en nvim corriendo | ~1.060 ms | **198–261 ms** | < 400 ms | ✅ |
| BufEnter re-ejecución 12k | 1.126–2.267 ms | **5–10 ms** | — | ✅ |
| BufEnter HTML real 7.581 líneas / 1,0 MB | ~1–2 s (calibrado: 6k→2.697 ms) | **5–7 ms** | — | ✅ |
| BufEnter DOM guardado 851 líneas / 1,56 MB | 1.559–1.638 ms | **3–5 ms** | — | ✅ (guard por bytes) |
| Guardado HTML 12k | ≥ 4.500 ms | **5.119–5.167 ms** | — | ⚠️ ver hallazgos |
| Drenaje post-start ($HOME / proyecto) | ≥ 7.060 ms / ~2.100 ms | **34 ms / 96 ms** | — | ✅ |

## Fixes aplicados

1. **`lua/plugins/lsp/cmp/html_ids.lua`**: root-scope (`vim.fs.root`) +
   `rg --files` async (`vim.system`) + skip sin proyecto. El glob sobre
   `$HOME` (7.057 ms) pasó a 0 ms (root = nil).
2. **`lua/plugins/lsp/mason.lua`**: `auto_update = false` (sin check de
   updates en cada arranque).
3. **`lua/plugins/treesitter.lua`**: solo instala parsers que faltan
   (loop local, 7 ms con todo instalado).
4. **`lua/config/patches.lua`** (+ `require` en `init.lua`): parche
   propietario de `nvim-html-css` — su parser es superlineal y re-parsea el
   buffer entero en **cada BufEnter y BufWritePre** (calibrado: 1k→165 ms,
   3k→538 ms, 6k→2.697 ms, 12k→4.101 ms puro Lua). El wrapper de
   `parsers.html.setup` salta si el buffer tiene **> 2.000 líneas o > 512
   KB**. Por líneas no bastaba: un DOM guardado de 1,56 MB en 851 líneas
   congelaba 1,6 s por parse (medido; tras el guard por bytes: 3–5 ms).

## Hallazgos (fuera del alcance de los fixes)

- **conform + prettier en HTML muy grande**: prettier supera
  `timeout_ms = 5000` en archivos ≥ ~1,3 MB → conform aborta a los 5 s y
  cae al fallback (LSP). Guardar un HTML de 12k cuesta ~5,1 s estables.
  En archivos normales (≤ 7k líneas) prettier termina en 248–511 ms. Si
  molesta, opciones: subir el timeout, sacar prettier del format-on-save
  en HTML > umbral, o formatear selección. Decisión del usuario; no se tocó.
- **treesitter parse frío** de HTML 12k: 369–546 ms (inherente al parser;
  el highlight es incremental y no bloquea la interacción).
- **markuplint huérfano**: si nvim muere sin apagar el cliente (p. ej.
  probes headless), el proceso sigue comiendo ~55 % CPU / 400 MB hasta que
  alguien lo mate. Candidato a candado o a revisión en 008.

## Criterios de aceptación

- [x] Arranque nvim con HTML 12k < 2 s — _evidencia: `--startuptime` mínimo
      626 ms (3 corridas, metodología arriba)._
- [x] Edición HTML 12k < 400 ms — _evidencia: `:edit` 198–261 ms en nvim
      corriendo (3 corridas)._
- [x] `nvim-html-css` no parsea buffers > 2.000 líneas o > 512 KB —
      _evidencia: BufEnter DOM 1,56 MB cayó de 1.559–1.638 ms a 3–5 ms
      tras activar el guard por bytes._
- [x] `html_ids` no escanea fuera de un proyecto — _evidencia: root = nil
      en `$HOME`, glob 0 ms (antes 7.057 ms)._
- [x] Sin regresión de config (carga ~410–425 ms, antes 363–483 ms) —
      _evidencia: sintaxis OK ×3 y métricas de carga en rango._
- [~] Guardado HTML 12k rápido — _prettier supera su timeout (~5,1 s);
      en archivos normales sí es rápido. Documentado arriba, pendiente de
      decisión del usuario._
