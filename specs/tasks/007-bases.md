# Tarea 007 — Bases (HTML/CSS/JSON/YAML/Lua/MD)

- **Estado:** ✅ Completada (absorbida por la 002 + ficha yaml en este cierre)
- **Depende de:** 002 (arquitectura por lenguaje)
- **Spec global:** `specs/GLOBAL.md`

## Objetivo

Soporte base R1–R5 de HTML, CSS, JSON, YAML, Lua y Markdown.

## Implementación

- **html-css** (002 F2): html + cssls + emmet (+ tailwind con guard),
  markuplint/stylelint con config del proyecto o fallback, fuente cmp
  `html_ids`, prettier web. Guard de rendimiento html-css en
  `patches.lua` (>2000 líneas o >512 KB, 003).
- **json** (002 F2): jsonls + prettier json + taplo (toml).
- **lua** (002 F2): lua_ls + lazydev + stylua.
- **markdown** (002 F2): marksman + markdownlint + mdformat.
- **yaml** (nuevo en este cierre): ficha `lua/languages/yaml/` —
  yaml-lsp (paquete ya instalado en mason pero sin cablear) + parser
  yaml (base treesitter) + prettier yaml (módulo web node-ts).

## Criterios de aceptación

- [x] html/css/json/lua/md: paridad verificada — _evidencia: 002 F2
      (paridad lint/format/servers) + 003 (rendimiento html)._
- [x] yaml: yamlls adjunta + prettier formatea + parser — _evidencia:
      `/tmp/opencode/yaml-test/config.yaml` (indent 8 espacios) →
      CLIENTS=yamlls, PARSER-yaml=true, conform changed=true._
- [x] sin attaches rogue — _evidencia: 002 F3._
