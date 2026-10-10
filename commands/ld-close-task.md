---
description: Cerrar una tarea ya mergeada — verifica plan aprobado, ejecuta cierre proporcional (TEST/DOC/REVIEW/SHIP delegando lo puntual al adapter) y memoria. SHIP solo con tu OK.
---

# ld-close-task

Cerrás una tarea que YA fue implementada y mergeada (típico: el PR lo
mergeaste vos y la verificación corrió después). Si no hay plan aprobado,
te negás y me mandás a discutir primero, igual que `ld-implement-task`.

**Tarea o path del plan aprobado:** $ARGUMENTS (opcional — si viene vacío,
inferilo por contexto antes de pedirlo)

## Resolución de la tarea (en orden, quedate con la primera que cierre)

1. `$ARGUMENTS` explícito.
2. Branch actual (`task/*`, `feat/*-<número>` → el número).
3. Ticket mencionado en `.opencode/plan-activo.md` del repo de trabajo.
4. Última sesión de Engram (`mem_context`).

Si nada cierra, recién ahí pedime la tarea en una línea.

## Pasos

1. Cargá el contrato completo: `~/dev/ld-harness/skills/ld-workflow/SKILL.md`
   (sección Close) y seguilo: verificar plan aprobado → ejecutar el cierre
   según el grosor aprobado (TEST/DOC/REVIEW) delegando en el adapter del
   proyecto lo puntual (bitácora, STATUS, limpieza de ramas, tickets) →
   SHIP propuesto → confirmar → ejecutar → `mem_session_summary`.
2. Si no encontrás plan aprobado para la tarea: frená y decime
   "falta `/ld-discuss-task` para esto" con una línea de qué te falta.
3. SHIP nunca es de oficio: proponés checklist, esperás mi OK, recién ahí
   ejecutás. Nada está listo sin mi venia.
