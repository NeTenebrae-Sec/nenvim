# Tarea 005 — React / JSX

- **Estado:** ✅ Completada (verificada en proyecto real vite react-ts)
- **Depende de:** 002 (arquitectura), 004 (node-ts)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Soporte React completo (R1–R5) sobre la ficha `languages/react/`.
Hereda de node-ts: vtsls (LSP), oxlint (lint), prettier (formato),
emmet (html-css), CMP cross-file. Añade lo específico de React:

## Alcance

1. **Ficha `lua/languages/react/`**:
   - `filetypes = { "javascriptreact", "typescriptreact" }` (jsx/tsx).
   - `dap`: `run()` = detección de proyecto vite/react → menú
     (dev/build/preview/test) en Kitty; fallback `node <archivo>` para
     archivos sueltos sin proyecto. `M.filetypes` explícito en los
     módulos dap para resolución determinista del runner (sin depender
     del orden de escaneo): react maneja jsx/tsx; node-ts solo js/ts.
   - Sin `lsp`/`lint`/`format` propios: los aporta node-ts (evita
     duplicar diagnósticos — GLOBAL §4 "sin duplicates").
   - `parsers`: tsx/jsx ya declarados por node-ts.
   - `tools`: ninguno nuevo (vite/oxlint/prettier ya cubiertos).
2. **Snippets** `snippets/react.json` + registro en
   `snippets/package.json` (language `javascriptreact`/`typescriptreact`):
   atajos de componente (rfc, impt, uset, …).
3. **R1 live-server**: `<leader>us` ya detecta vite → `npm run dev`
   equivalente (`vite dev`); verificar con proyecto react real.

## Verificación (proyecto real — `/tmp/opencode/react-test`, vite react-ts)

- [x] vtsls adjunta a `.tsx`; oxlint diagnostica un error insertado;
      prettier formatea; parser tsx activo — _evidencia: CLIENTS=
      emmet_language_server,vtsls; DIAGS=1 [oxlint:2] (no-debugger);
      conform changed=true con línea mangleada; PARSER-tsx=true._
- [x] DAP: `pwa-node` + `configurations.typescriptreact` presentes —
      _evidencia: cfg.tsreact=true pwa-node=true._
- [x] Runner `<leader>dr` en `.tsx` resuelve el módulo react —
      _evidencia: detect()=true, prompt "React: select execution
      action:"; nextjs detect()=false; en `.tsx` suelto (sin
      proyecto) detect()=false y el runner degrada a `node <archivo>`
      sin abrir menú._
- [x] Snippets react registrados — _evidencia: 9 triggers [imn, impt,
      rac, rfc, rmap, usct, uset, usrf, usst] decodificados y
      registrados vía `snippets/package.json`._
- [x] CMP cross-file — _evidencia: completion `__sal` devuelve
      `__saludoR` importado de `./__x-util` (vtsls)._
- [x] `<leader>us` detecta vite — _evidencia: `vite dev` del proyecto
      sirve con HTTP 200 en el comando que construye el módulo._

## Riesgos y notas

- Sin `lsp`/`lint` propios la ficha es deliberadamente delgada: si un
  proyecto react necesita reglas eslint-plugin-react, se corren con
  `npm run lint` (paridad CLI↔nvim, patrón 001 §J).
- El runner de archivos sueltos sin proyecto degrada a `node <file>`
  (paridad con el comportamiento previo de node-ts).
