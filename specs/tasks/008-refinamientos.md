# Tarea 008 — Refinamientos globales

- **Estado:** ✅ Completada (absorbida por 002/F3 + auditoría final aquí)
- **Depende de:** 001, 002, 003
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Resolver los problemas transversales del diagnóstico inicial:
flood `html-css-lsp`, SIGTERM de TSServer, semantic tokens off,
stack TS único, clientes `tailwindcss`/`html-css` sobrantes.

## Resolución por ítem

| Ítem | Resolución | Evidencia |
| --- | --- | --- |
| flood `html-css-lsp` | El plugin solo spawna el server dentro de proyectos node (raíz con package.json); 0 menciones en sesiones nuevas | 002 F3 |
| SIGTERM de TSServer | vtsls único y estable; el SIGTERM histórico era del typescript-language-server viejo (ya no adjunta) | 002 F2 (vtsls único) |
| semantic tokens off | `core/lsp/guards.lua` limpia `semanticTokensProvider` en cada LspAttach (resaltado = treesitter) | 002 F0 |
| stack TS único | vtsls es el único server TS (typescript-language-server solo aporta el tsdk que lee astro-ls, no adjunta) | 002 F2/F3 |
| tailwind sobrante | guard root_dir: config tailwind/postcss o dep `tailwindcss` en package.json | 002 F3 |
| html-css sobrante | guard `patches.lua` (>2000 líneas o >512 KB) + root-scope del escaneo | 003 |

## Criterios de aceptación

- [x] Cada ítem resuelto con evidencia (tabla superior).
- [x] Auditoría final en sesión viva: sin clientes rogue ni
      semantic tokens — _evidencia: probe neteumbra (.astro y .ts):
      CLIENTS=astro,emmet / vtsls únicos, SEMANTIC-TOKENS-ON=ninguno,
      TS-LEGACY-SERVERS=ninguno; lsp.log desde el último arranque: 0
      menciones html-css/tailwind/SIGTERM; arranque 262–438 ms (sin
      regresión 003)._
