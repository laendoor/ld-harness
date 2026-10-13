---
name: ld-improve-harness
description: Mejorar el propio ld-harness desde cualquier repo — captura la propuesta, la discute si no es trivial, valida, muestra diff y commitea en un branch solo con OK; merge y push los hace el usuario. El único comando que modifica el harness. Usar vía /ld-improve-harness.
---

# ld-improve-harness — el harness se opera a sí mismo

Sos el único comando que modifica `~/dev/ld-harness`. Todo lo demás lo usa;
esto lo cambia. Esa asimetría pide contrato estricto.

**Contexto de trabajo:** `HARNESS=~/dev/ld-harness`, sin importar desde qué
repo/proyecto me invocaron. Los cambios viven en el harness; los symlinks se
regeneran con `setup.sh`.

## Mejora pedida

$ARGUMENTS (si vacío: pedila en una línea y recién ahí arrancá)

## Pasos

### 1. Clasificar

- **Trivial** (typo, 1 línea, rename interno, link caído): aplicar directo,
  ir al paso 3.
- **No-trivial** (skill/command nuevo, cambio de contrato, permisos, hooks):
  mini-discuss numerado (dudas + propuesta/alternativa, formato de
  `ld-workflow` pero corto) y frenar esperando OK.

### 2. Aplicar (solo con OK si fue no-trivial)

Respetar convenciones del repo: `ld-` en todo lo propio, command fino + skill
grueso, nunca vendorear terceros, README al día si cambia conducta.

### 3. Validar (siempre, sin excepción)

1. `bash $HARNESS/setup.sh` — regenera symlinks y purga colgados.
2. `node --check` en cada `plugins/*/opencode-plugin.js` tocado.
3. Frontmatter válido en `commands/*.md` y `skills/*/SKILL.md`
   (`description` / `name` + `description`).
4. `ls` en destinos: symlinks resuelven en opencode y claude.

Si algo falla: reportar, no seguir al paso 4.

### 4. Ship (proponer → confirmar → ejecutar, como `ld-sync`)

1. Mostrar diff + stat. Esperar OK explícito sobre el diff.
2. Con OK: commit en un branch `improve/<slug>` (ld-gate bloquea commits en
   `main` y todo push), mensaje claro en español o inglés según el historial.
3. Pasar los comandos para que los corra el usuario:
   `git -C ~/dev/ld-harness switch main && git -C ~/dev/ld-harness merge --ff-only improve/<slug> && git -C ~/dev/ld-harness push`.
   Si `main` avanzó y el ff no entra: reportar, nunca resolver solo.
4. Sin OK: dejar todo commiteado local o sin commitear según me pidan, y decir
   qué falta.

## Prohibido

- Tocar cualquier repo que no sea `$HARNESS` (ni el proyecto invocante).
- `push --force`, resolver merges solo, commitear en otros repos.
- Aplicar sin validar (paso 3) o commitear sin OK sobre el diff (paso 4).
- Este skill no reemplaza a `ld-sync`: improve = cambiar, sync = transportar.
