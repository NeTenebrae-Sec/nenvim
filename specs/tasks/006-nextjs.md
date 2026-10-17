# Tarea 006 — Next.js

- **Estado:** ✅ Completada (verificada en proyecto real create-next-app,
  app router)
- **Depende de:** 002 (arquitectura), 004 (node-ts), 005 (react)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Soporte Next.js (R1–R5) sobre la ficha `languages/nextjs/`, con
verificación en un proyecto real (create-next-app, app router).

## Alcance

1. **Ficha `lua/languages/nextjs/`**:
   - `filetypes`: hereda jsx/tsx de node-ts (sin declarar lsp/lint
     propios — mismas razones que react: sin duplicados; las reglas
     eslint-config-next se corren vía `npm run lint`, paridad CLI).
   - `dap`: `run()` = detección de dep `next` en package.json → menú
     (dev/build/start/lint) en Kitty; fallback `node <archivo>`.
     `M.filetypes` = jsx/tsx… **conflicto con react**: resolución —
     el runner prefiere la ficha cuyo `dap.detect()` confirma el
     proyecto con mayor `dap.priority` (next=20 sobre react=10: todo
     proyecto next instala react, dep `next` ⊂ `react`); sin detect
     confirmado, cualquier `dap.run()` matcheado sirve de fallback
     (en archivos sueltos react/next degradan a `node <archivo>`).
2. **Snippets** `snippets/next.json` + registro en
   `snippets/package.json` (language `javascriptreact`/`typescriptreact`):
   `'use client'`, página/app-router, metadata, etc.
3. **R1 live-server**: extender `plugins/live-server.lua` con detección
   next (dep `next` en package.json → `next dev` del proyecto, puerto
   por defecto 3000, mismo flujo de URL/stop que astro/vite).
4. **R4 extra**: vtsls con `tsconfig` de next funciona tal cual;
   verificar diagnósticos/hover en `app/page.tsx`.

## Verificación (proyecto real — `/tmp/opencode/next-test`, create-next-app app router)

- [x] vtsls adjunta en `app/page.tsx`; oxlint diagnostica error
      insertado; prettier formatea; parser tsx — _evidencia: CLIENTS=
      emmet_language_server,vtsls; DIAGS=1 [oxlint] (no-debugger);
      conform ok; parser tsx (heredado node-ts)._
- [x] DAP: configurations.typescriptreact presentes — _evidencia:
      cfg.tsreact=true pwa-node=true._
- [x] Runner en `.tsx` con dep `next` → menú next; sin dep →
      fallback — _evidencia: EN next-test react detect()=true (instala
      react) y next detect()=true, gana next por priority: prompt
      "Next.js: select execution action:"; en suelto ambos false →
      fallback a `node <archivo>` sin menú._
- [x] Snippets next registrados — _evidencia: 6 triggers [nc, nimg,
      nlayout, nlink, nmeta, npage]._
- [x] live-server: detección `next` → `next dev` — _evidencia:
      node_modules/.bin/next legible en el proyecto (rama is_next del
      módulo) y `next dev` anuncia http://localhost:3000 (mismo
      patrón de URL que parsea el módulo)._
- [x] CMP cross-file en el proyecto — _evidencia: completion `__sal`
      devuelve `__saludoN` importado de `../lib/util` (vtsls, 987
      items)._

## Riesgos y notas

- create-next-app descarga bastante (deps + turbopack); la verificación
  usa el proyecto creado en `/tmp/opencode/` y se limpia si ensucia.
- El menú del runner se verifica invocando la lógica de detección
  directamente (headless no bombea `vim.ui.select`).
