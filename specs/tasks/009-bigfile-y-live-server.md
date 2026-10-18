# Tarea 009 — Live-server sin .git + bigfile suave + guard de rainbow

- **Estado:** ✅ Completada
- **Depende de:** 001 (R1 live-server), 003 (guards de rendimiento)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

1. **Fix R1**: `<leader>us` no detectaba proyectos web sin `.git`
   (scaffolds nuevos, p. ej. `~/test/demo`): la raíz caía al directorio
   del archivo, el binario de astro no existía ahí y se caía a vite.
2. **Bigfile suave**: `snacks.bigfile` cambiaba el filetype a `bigfile`
   a partir de 1.5 MB, matando LSP/lint/formato/treesitter de golpe.
   Se quiere "todo activo lo más rápido posible": umbral alto y la
   degradación reservada a monstruos; más un comando `:Toggles` con la
   lista de toggles de snacks (treesitter, diagnostics, dim, words…).
3. **Guard de rainbow** (descubierto durante la verificación del
   bigfile): `rainbow-delimiters` con la query global `[""]` recorre
   **todos los nodos del árbol en Lua** a cada parse completo con
   coste **cuadrático** (2k líneas ≈140 ms, 10k ≈3.3 s, 50k ≈97 s →
   editor congelado). Attribution: 97.4 s de 97.6 s de parse. Es la
   causa real de los cuelgues con archivos medianos-grandes.

## Alcance

### A. Fix live-server root (`lua/plugins/live-server.lua`)

`get_intelligent_project_root()` busca hacia arriba, en orden:

1. configs de framework (`astro.config.*`, `next.config.*`) — cubre
   scaffolds sin git;
2. `package.json` y `.git`;
3. fallback actual: directorio del propio archivo (web estática sin
   manifiesto).

Mismo criterio de marcadores que los `root_markers` de los motores LSP.

### B. Bigfile suave (`lua/plugins/snacks.lua`)

- `bigfile.size = 5 MB` y `bigfile.line_length = 4000`: archivos
  ≤5 MB con líneas normales trabajan con todo (LSP, lint, treesitter,
  snippets); la red de seguridad nativa de snacks (ft `bigfile`)
  solo actúa sobre >5 MB o minificados extremos (línea media >4000).
- Comando `:Toggles` → `vim.ui.select` sobre `Snacks.toggle.toggles`
  con los built-in instanciados perezosamente: treesitter, diagnostics,
  inlay_hints, indent, dim, words, scroll, animate, line_number.
  Bucle: elige → alterna → reabre → cancelar cierra. La UI en sesión
  real es el picker de snacks (`ui_select = true` por defecto), la
  misma de los comandos "multiple" de java. Sin keymap (decisión de
  uso). Sin toggle de LSP: esta versión de snacks no lo trae
  (`Snacks.toggle` no tiene factory `lsp`).
- El guard de html-css (`config/patches.lua`) se mantiene automático.

### C. Guard de rainbow en buffers grandes (`lua/plugins/UI/rainbow.lua`)

Wrap de `on_attach`/`on_reset` de la strategy global (el módulo
`rainbow-delimiters.strategy.global`, cacheado en `require` —
`rainbow.strategy["global"]` es su nombre string): por encima de
**3000 líneas** no se registran sus callbacks de parse (sin colores
rainbow en ese buffer; LSP/treesitter/lint siguen activos). Por debajo
de 3000 el comportamiento es idéntico al anterior (≤~140 ms de walk).

## Criterios de aceptación

- [x] `<leader>us` (toggle) en `~/test/demo` (astro sin .git):
      framework=astro, URL puerto 4321 parseada, stop limpio —
      _evidencia: probe 009A → `index.astro ft=astro url_ok=true
      framework=astro port=4321 root_huerfano=ninguno 7641ms` +
      `stop-limpio=true`._
- [x] Paridad neteumbra desde `Footer.astro`: framework=astro, raíz
      del repo — _evidencia: probe 009A → `Footer.astro ft=astro
      url_ok=true framework=astro port=4321 root_huerfano=ninguno
      8179ms` + `stop-limpio=true`._
- [x] Fixture JSON ~3 MB (impreso): LSP jsonls adjunto + treesitter
      activo + filetype real (NO bigfile) — _evidencia: probe 009B
      final → `edit_ms=1924 ft=json lines=270002`,
      `ts_parse ok=true ms=738`, `ts_highlight_activo=true`,
      `jsonls_adjunto=true ms=3751`, `clients=[jsonls]`._
- [x] Fixture HTML ~5k líneas: LSP adjunto + filetype real —
      _evidencia: probe 009B final → `edit_ms=256 ft=html
      lines=6643`, `lsp=true ms=1019
      clients=[emmet_language_server,html-css-lsp]`._
- [x] Fixture JSON >5 MB: degradación de seguridad (ft bigfile) —
      _evidencia: probe 009B final → `edit_ms=3185 ft=bigfile
      degrada=true` (9 MB)._
- [x] `:Toggles` registrado: abre, lista los built-in, alterna el
      elegido y reabre en bucle hasta cancelar — _evidencia: probe
      flow → `exists=true`, `cmd_ok=true`, `ui_select_calls=2
      elegio_treesitter=true`, `ts_before=true → nil (stop) →
      restaura=true`; registro = [Animations, Diagnostics, Dimming,
      Indent Guides, Inlay Hints, LSP Words, Line Numbers, Smooth
      Scroll, Treesitter Highlight] (9)._
- [x] Guard rainbow: sin walk por encima de 3000 líneas y rainbow
      intacto por debajo — _evidencia: attribution
      `cb changedtree:rainbow-delimiters/.../global.lua calls=1
      ms=97421.4` sobre `parse_total_ms=97578` (antes); curva
      post-guard `5k→parse_ms=9`, `25k→62`, `50k→150` (antes
      1113/23499/91067) y `2k líneas rb_attached=true` con
      edit_ms=499 (walk ≤~140 ms, igual que siempre)._
- [x] `<leader>us` notifica al instante y la de URL sin retraso —
      _evidencia: probe de timestamps (hook sobre `vim.notify` +
      `xdg-open` falso de 8 s): post-fix `key→1ª notify=2 ms`
      ("Web: iniciando astro (demo)..."), `url→sirviendo=0 ms`,
      `stop→detenido=9 ms` y tabla limpia; pre-fix la primera
      notificación del servidor salía al parsear la URL
      (`key→url=1652–4921 ms` de boot, sin feedback). Causa real
      descartada con medida: `system("xdg-open … &")=10 ms` no
      bloquea — era solo el boot del dev server._

## Riesgos y notas

- Los probes de live-server usan `xdg-open` falso
  (`/tmp/opencode/fakebin`) para no abrir el navegador real.
- El cuelgue original no aparecía en `:profile func *` porque el
  walk de rainbow va compilado con LuaJIT (sin hooks); se atribuyó
  con wrappers de timing sobre `p._callbacks` y con una backtrace
  de gdb (`ts_node_end_point` ← luajit pcall).
- jsonls sobre 3 MB adjunta en ~3.7 s (node indexa el contenido);
  árbol treesitter de 270k líneas parsea en ~740 ms (sano).
- El walk de rainbow por debajo de 3000 líneas es cuadrático en el
  peor caso del umbral: ≈300 ms exactamente en 3000 líneas.
