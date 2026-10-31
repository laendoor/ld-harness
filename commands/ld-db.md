---
description: Operar bases de datos — dumps, restores, migraciones, consultas a producción y correcciones ad-hoc. Read-only por defecto, backup verificado, escritura con rowcount esperado.
---

# ld-db

Datos no se recuperan con un `git revert`.

**Tarea:** $ARGUMENTS (vacío = solo inventario read-only)

**Anunciar al inicio:** "Usando ld-db — inventario y backup antes de escribir."

## Pasos

1. Cargá el procedimiento completo: `~/dev/ld-harness/skills/ld-db/SKILL.md` y seguilo.
2. Inventario read-only: motor, tamaño, locks y fecha del último restore probado.
3. Para cualquier escritura: SELECT previo, rowcount esperado y OK explícito antes de
   correr.
4. Verificar los datos con una query real y reportar con la plantilla.
