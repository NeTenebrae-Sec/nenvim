# Tarea 004 — Node.js / TypeScript

- **Estado:** ✅ Completada (absorbida por la 002; cierre con evidencia)
- **Depende de:** 002 (arquitectura por lenguaje)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Soporte completo Node.js/TypeScript: LSP, lint, formato, DAP, snippets
de proyecto y CMP cross-file (R1–R5).

## Implementación (ya realizada en 002)

La ficha `lua/languages/node-ts/` absorbe todo el alcance:

- **R4 LSP**: vtsls con root_dir guard (tsconfig/jsconfig/package.json;
  sin `.git` suelto — guard anti-rogue F3 de la 002).
- **R3 lint**: oxlint en javascript/typescript/jsx/tsx.
- **Formato**: módulo prettier "web" (`languages/node-ts/format.lua`):
  args dinámicos por config local del proyecto, cubre también html/css/
  vue/svelte/astro/json/yaml.
- **R2 DAP/runner**: `dap.lua` — `pwa-node` (js-debug) + `run()` node en
  Kitty. En archivos react el runner lo resuelve la ficha `react` (005).
- **R1**: `<leader>us` (vite) — `plugins/live-server.lua`.
- **R5 CMP cross-file**: verificado en 002 F4 (import `defaultLocale`
  desde `config.ts`, 309 items).
- Extras: `:Jsconfig`.

## Criterios de aceptación

- [x] R4/R3/R5 verificados en vivo — _evidencia: 002 F2 (paridad) y
      002 F4 (R5: completion cross-file vtsls en neteumbra)._
- [x] Guards anti-rogue — _evidencia: 002 F3 (.ts sin manifiesto node →
      0 clientes)._
- [x] DAP pwa-node registrado — _evidencia: 002 F2 probe DAP-ADP
      (pwa-node presente)._

## Riesgos y notas

Sin trabajo nuevo en esta tarea: todo quedó implementado y verificado
dentro de la 002.
