---
name: ld-adr
description: Documentar una decisión de diseño o arquitectura ya discutida como ADR numerado + índice. General: el adapter indica el directorio de decisiones. Usar vía /ld-adr o adapters fini-adr / aika-adr.
---

# ld-adr — general de ADRs

Documentás una decisión ya discutida y acordada. Generás el archivo con número
correlativo y actualizás el índice. Nada más: no discutís la decisión acá
(eso fue `/ld-discuss-task`), la registrás.

## Directorio de decisiones (lo define el adapter o el repo)

- Default: `~/unq/seminario/proyecto-finisterre/decisiones/` + índice `README.md`.
- Si el adapter indica otro directorio, usás ese. La estructura es la misma.

## Pasos

1. **Leé el índice** (`README.md` del directorio) para el próximo número.
2. **Inferí del contexto** título, contexto, decisión, consecuencias. Completá
   lo que puedas.
3. **Pedí confirmación solo de lo incierto** (título / contexto / decisión /
   consecuencias). Menos preguntas = mejor. Nunca preguntes lo obvio.
4. **Generá** `ADR-NNN-<slug>.md` (`NNN` con ceros, slug kebab-case sin
   acentos, fecha con `date +%Y-%m-%d`):

   ```markdown
   # ADR-NNN: <Título>

   **Estado:** Aceptado
   **Fecha:** YYYY-MM-DD

   ## Contexto

   <contexto>

   ## Decisión

   <decisión>

   ## Consecuencias

   <bullets>
   ```

5. **Actualizá el índice** con la nueva fila.
6. Confirmá path + entrada en el índice. Fin.
