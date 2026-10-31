#!/usr/bin/env bash
# PreToolUse hook: deny the shell patterns nobody runs on purpose. Same list as
# opencode-plugin.js — if one changes, change the other.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"

deny() { # deny <reason>
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("[ld-gate] " + $reason)
    }
  }'
  exit 0
}

# ERE, not PCRE: macOS grep has no -P. Case-insensitive: los comandos de DB
# se escriben en mayúsculas (DROP DATABASE) y en minúsculas (alembic downgrade).
#
# Los patrones de "texto" son palabras que también aparecen en prosa: el cuerpo
# de un issue o un mensaje de commit que documenta el rollback. Si el comando
# arranca con gh o git y no trae sustitución ni separadores, el único binario que
# corre es ese, y lo que sigue es dato. Los estructurales se escanean igual.
# shortcut: `git -c alias.x='!dropdb y' x` se colaría; eso lo cubre el revisor.
text_scan=1
# Prefijo inocuo: `cd X &&` antes del comando real. Sin esto la exención no se
# activa nunca, porque el shell habitual arranca con cd.
probe="$(printf '%s' "$cmd" | sed -E 's/^[[:space:]]*(cd[[:space:]]+[^&[:space:]]+[[:space:]]*&&[[:space:]]*)+//')"
# Una sola línea: un script multilínea que empiece con git podría llevar un
# comando destructivo en la segunda línea, y la exención lo taparía.
if [ "$(printf '%s' "$probe" | wc -l | tr -d ' ')" = "0" ] &&
  grep -Eq '^[[:space:]]*(gh|git)[[:space:]]' <<<"$probe" &&
  ! grep -Eq '([$][(]|`|;|&|[|])' <<<"$probe"; then
  text_scan=0
fi

for re in \
  'rm[[:space:]]+-rf?[[:space:]]+/([[:space:];&|]|$)' \
  'rm[[:space:]]+-rf?[[:space:]]+/\*' \
  'mkfs(\.|[[:space:]]|$)' \
  ':[[:space:]]?\(\)[[:space:]]?\{[[:space:]]?:[[:space:]]?\|[[:space:]]?:[[:space:]]?&[[:space:]]?\}[[:space:]]?;' \
  '>[[:space:]]?/dev/sd[a-z]([^[:alnum:]]|$)'; do
  if grep -Eqi -- "$re" <<<"$cmd"; then
    deny "blocked by catastrophic pattern $re"
  fi
done

if [ "$text_scan" = 1 ]; then
  for re in \
    'alembic[[:space:]-]+downgrade' \
    '(^|[^[:alnum:]_])dropdb([^[:alnum:]_]|$)' \
    'pg_restore[^\n]*--clean([^[:alnum:]_]|$)' \
    'docker[[:space:]]+volume[[:space:]]+rm([^[:alnum:]_]|$)' \
    'docker[^\n]*down[^\n]*([[:space:]]-[a-z]*v[a-z]*|--volumes)([^[:alnum:]_]|$)'; do
    if grep -Eqi -- "$re" <<<"$cmd"; then
      deny "blocked by catastrophic pattern $re"
    fi
  done

  # SQL destructivo sólo si el comando habla con la base. Dos greps separados
  # porque el heredoc trae el cliente y la sentencia en líneas distintas, y grep
  # evalúa línea por línea.
  if printf '%s\n' "$cmd" | grep -Eqi -- '(^|[^[:alnum:]_])(psql|dropdb|pg_restore|pg_dumpall)([^[:alnum:]_]|$)|alembic[[:space:]-]' &&
    printf '%s\n' "$cmd" | grep -Eqi -- '(^|[^[:alnum:]_])(truncate|delete[[:space:]]+from|drop[[:space:]]+(database|schema|table|extension|column))([^[:alnum:]_]|$)'; then
    deny "destructive SQL (client + statement)"
  fi
fi
