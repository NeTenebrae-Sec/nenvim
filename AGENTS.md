# Reglas de agente — nvim-mcp

El usuario edita código en Neovim. Tú lo controlas mediante las herramientas de **nvim-mcp**. Ya conoces Vim — usa ese conocimiento.

> Basado en AGENTS-EXAMPLE.md de paulburgess1357/nvim-mcp (upstream),
> adaptado a este proyecto. Spec: specs/nvim/tasks/000-mcp-setup.md.

## Estilo de código: Ponytail

Cuando escribas o modifiques código de esta config, aplica el skill
**ponytail** (`~/.config/nvim/.opencode/skill/ponytail/SKILL.md`): el cambio
mínimo que resuelva del todo, sin abstracciones ni features que nadie pidió, reutilizando los patrones y estructura ya existentes. La fuente de verdad del principio es `ponytail.md` — no dupliques su contenido aquí.

## Cuándo consultar el estado del editor

`get_state_brief` te dice qué está mirando el usuario ahora: el archivo
activo, la posición del cursor y qué archivos están abiertos en buffers.
Llámalo cuando tu siguiente paso dependa de eso, y omítelo cuando no. Una
llamada que el turno no necesita solo retrasa la respuesta.

Llámalo **una vez**, al inicio de un turno en el que vas a:

- Leer o editar un archivo. Necesitas `buffers` para elegir entre
  herramientas de buffer y disco, y el usuario pudo editar o mover cosas
  desde tu último turno.
- Actuar en el editor: abrir un archivo, cambiar ventanas, resaltar,
  anotar o enviar texto a una terminal.
- Responder algo que apunte a la vista actual del usuario: "esta
  función", "aquí", "el archivo actual", "qué falla aquí?".

Omítelo cuando el turno no dependa del editor:

- Preguntas de seguimiento sobre algo ya conversado ("por qué lo hiciste
  así?", "explícame más", "y si probamos el otro enfoque?").
- Preguntas generales, planificación y diseño.
- Trabajo fuera del editor (shell, git, redacción de mensajes).

Para seguimiento sobre código leído antes, responde con lo que ya tienes.
Vuelve a leer el buffer solo si el usuario dice que cambió, o si la
respuesta depende del texto exacto actual.

Una llamada por turno es suficiente. Dentro de un turno, no re-verifiques
tras tus propias ediciones o comandos; sus resultados ya dicen qué cambió.
Entre turnos no persiste nada: si un nuevo turno necesita el editor,
consulta de nuevo.

Usa `get_state` completo solo cuando necesites contexto profundo
(plegados, marcas, diagnósticos, highlights, texto virtual, todas las
ventanas).

## Reglas

1. **Si un archivo está en `buffers`, usa siempre herramientas de buffer —
   no disco.** Lee con `read_full_buf` (o `read_buf_range` para un tramo).
   Edita con `find_and_replace_buf` (o `write_full_buf` para contenido
   completo). Así el usuario ve el cambio de inmediato y tiene undo. Usa
   disco solo si el archivo no está en `buffers`.

2. **El contexto del usuario es la ventana activa.** Si la ventana activa
   es una terminal, el contexto de archivo del usuario es la ventana
   alterna. Al abrir archivos en ese caso, usa
   `send_command(["wincmd p", "e <file>", "wincmd p"])`. Si la terminal es
   la única ventana, usa `send_command("vsplit <file>")` para no
   reemplazarla.

3. **Mantén la ventana de terminal en su lugar al dividir.** Si existe una
   terminal, abre nuevos splits desde una ventana que no sea terminal para
   que la terminal quede donde está. Cambia primero a una ventana de
   archivo (`wincmd p` o apuntarla directamente), ejecuta el split ahí, y
   vuelve si hace falta.

## Terminales

**Para poner texto en una terminal, usa `send_to_terminal` — nunca
`send_keys`, modo insert ni las herramientas de edición de buffer** (los
buffers de terminal no son editables). Escribe al canal de job de la
terminal, así que funciona sin importar foco o modo y nunca mueve el
cursor del usuario.

- Las terminales abiertas aparecen bajo `terminals` en `get_state_brief` /
  `get_state`; apunta una por su `buf` o `name`. Con una sola terminal
  abierta, el argumento puede omitirse.
- Por defecto (`submit=false`): el texto queda en el prompt para que el
  usuario revise y presione Enter. Casi siempre es lo que quieres.

**⚠ OBLIGATORIO: nunca pases `submit=true` salvo que el usuario haya
pedido explícitamente EJECUTAR el comando en ese mensaje. "Poner",
"pegar", "escribir" o "preparar" un comando siempre significa
`submit=false`. Que tú sugieras un comando no es permiso para ejecutarlo.
Ante la duda, `submit=false`.**

## Colores

`highlight_range` y `add_virtual_text` aceptan dos formatos de color:

- Hex (ej. `#3b4048`) — se usa tal cual.
- Nombre de grupo de highlight (ej. `Comment`, `DiagnosticError`) — se
  adapta al colorscheme del usuario. En `highlight_range`, el fg del grupo
  se usa como fondo de línea; en `add_virtual_text`, el grupo se usa
  directo.

Nombres desconocidos (incluidos literales de color como `Red`) devuelven
error. Usa hex o un grupo de highlight válido.

### Grupos recomendados

- Notas / contexto (default de ambas herramientas): `Comment`
- Errores: `DiagnosticError`
- Advertencias: `DiagnosticWarn`
- Info: `DiagnosticInfo`
- Pistas: `DiagnosticHint`
- Bien / éxito: `DiagnosticOk`

Pasa el nombre del grupo como argumento `color`. Ambas herramientas usan
`Comment` si no se indica color.

## Texto virtual

**⚠ OBLIGATORIO: cada item de texto de `add_virtual_text` /
`add_virtual_texts` DEBE empezar con `※ ` (U+203B, "Reference Mark"). Sin
excepciones, cada llamada, cada item.** Ejemplo:
`text=["※ swap if reversed"]`.

- Cada anotación en **una sola línea y corta**. Sin `\n`. Un item por
  lista `text`. Si necesitas más, coloca varios items cortos en líneas
  consecutivas.
- `color`: default `Comment`. Usa grupos `Diagnostic*` solo cuando la
  semántica lo exija.
- `position`: default `"eol"`. Usa `"above"` / `"below"` solo si la línea
  ya es larga.

## Múltiples instancias

Si hay varias instancias de Neovim, `connect` las lista. Pregunta al
usuario cuál — no adivines.

## Verificación en vivo (spec workflow de este proyecto)

Este repo sigue **Spec Driven Development** (`specs/nvim/GLOBAL.md`). Al
verificar criterios de spec:

- Observa la realidad (clientes adjuntos, capabilities, diagnósticos,
  `source=` de cada diagnóstico) y reporta lo observado — nunca asumas
  que "debería funcionar".
- Para probar duplicaciones de diagnóstico, usa
  `get_state`/`get_diagnostics` y revisa el `source` de cada uno
  (astro-ls vs eslint vs vtsls).
- Los cambios a la config de nvim se editan en disco (la config vive en
  este repo y no suele estar abierta en buffers) y nvim los recarga con
  `:source` / reinicio según lo que pidas al usuario.
