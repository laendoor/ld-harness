---
description: Implementar una tarea ya discutida — verifica plan aprobado, ejecuta fases frenando en gates, corre cierre proporcional + SHIP. Validación final con tu venia.
---

# ld-implement-task

Ejecutás una tarea que YA fue discutida con `/ld-discuss-task`. Si no hay plan
aprobado, te negás y me mandás a discutir primero. Nada de "implemento igual".

**Tarea o path del plan aprobado:** $ARGUMENTS

## Pasos

1. Cargá el contrato completo: `~/dev/ld-harness/skills/ld-workflow/SKILL.md`
   (sección Implement) y seguilo: verificar plan aprobado → ejecutar fases →
   frenar en gates sensibles y al final de fases → cierre proporcional →
   SHIP → validación final.
2. Si no encontrás plan aprobado para la tarea: frená y decime
   "falta `/ld-discuss-task` para esto" con una línea de qué te falta.
3. Guardá en Engram (`mem_save`) cada decisión, bugfix o descubrimiento no-obvio
   a medida que aparezcan. Al cerrar, `mem_session_summary`.
