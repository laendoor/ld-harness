---
name: ld-sync
description: Política de sync del propio ld-harness. Check = solo reporta (pull disponible / push pendiente) sin cambiar estado. Apply = fetch + diffs + aplica solo con OK explícito + doctor. Nunca pull/push automático. Usar vía /ld-sync.
---

# ld-sync — política de sync (notify-only)

El harness avisa, no aplica. Pull y push comparten política y comando.

## Check (default)

Sin tocar estado (sin fetch, sin pull, sin push):

1. `git -C ~/dev/ld-harness status --short --branch` → push pendiente sí/no.
2. Comparar `HEAD` vs `@{u}` con los refs ya conocidos (sin red):
   pull disponible sí/no (o "desconocido, sin fetch reciente").
3. Reportar en 3 líneas y frenar:
   `pull: <sí/no> · push: <sí/no> · siguiente paso: <nada | /ld-sync apply>`

## Apply (solo con OK explícito previo al apply, no solo al comando)

1. `git fetch origin`.
2. Mostrar diff pull (`HEAD..@{u}`, stat + commits) y diff push (stat + commits
   locales no pusheados). Esperar OK explícito sobre los diffs.
3. Con OK: `git pull --ff-only` (si hay merge, frenar y pedir instrucciones —
   nunca resolver merge solo), luego `git push`.
4. Doctor post-sync:
   - frontmatter válido en todo `commands/*.md` y `skills/*/SKILL.md`
     (`name` + `description` presentes, `SKILL.md` en mayúsculas),
   - symlinks de `setup.sh` resuelven (`ls` en destinos),
   - scan rápido de patrones riesgosos en lo nuevo (exfiltración, shell abuso,
     secretos literales). Si algo huele mal: reportar y no cargar hasta revisar.

## Prohibido

- Pull/push automático en hooks, cron o sesiones. El check puede correr en
  `session.created`; el apply siempre lo invoco yo.
- Resolver merges solo, commitear en nombre mío sin pedirme, pushear `--force`.
