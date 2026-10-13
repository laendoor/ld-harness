---
description: Sync del propio ld-harness — check avisa si hay updates o pushes pendientes (default), apply hace el pull con tu OK + doctor; el push es tuyo. Nunca aplica solo.
---

# ld-sync

Harness que se auto-actualiza solo no: este comando es notify-only por defecto.

**Modo:** $ARGUMENTS (vacío o `check` = solo avisar; `apply` = mostrar diffs y
aplicar con mi OK explícito)

## Pasos

1. Cargá la política completa: `~/dev/ld-harness/skills/ld-sync/SKILL.md` y
   seguila según el modo pedido.
2. En modo `check`: reportá estado en 3 líneas (pull disponible sí/no,
   push pendiente sí/no, qué sigue) y frená. Nunca fetchees ni apliques nada
   que cambie estado sin que yo lo pida.
