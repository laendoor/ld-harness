---
description: Operar producción — deploy, parches, backups, dumps y diagnóstico de contenedores. Read-only primero, rollback antes del cambio, verificación desde afuera, gotcha al RUNBOOK.
---

# ld-ops

Producción no es un lugar para improvisar: cada paso o lee o muta, nunca las dos.

**Tarea:** $ARGUMENTS (vacío = solo inventario read-only)

**Anunciar al inicio:** "Usando ld-ops — inventario antes de tocar nada."

## Pasos

1. Cargá el procedimiento completo: `~/dev/ld-harness/skills/ld-ops/SKILL.md` y seguilo.
2. Inventario read-only y pegalo antes de proponer cualquier cambio. Sin esa salida no se
   propone nada.
3. Para cada paso que muta: mostrar el comando completo, nombrar el rollback, esperar mi
   OK explícito.
4. Verificar desde afuera y reportar con la plantilla de cinco líneas.
