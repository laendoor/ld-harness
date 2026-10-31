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
for re in \
  'rm[[:space:]]+-rf?[[:space:]]+/([[:space:];&|]|$)' \
  'rm[[:space:]]+-rf?[[:space:]]+/\*' \
  'mkfs(\.|[[:space:]]|$)' \
  ':[[:space:]]?\(\)[[:space:]]?\{[[:space:]]?:[[:space:]]?\|[[:space:]]?:[[:space:]]?&[[:space:]]?\}[[:space:]]?;' \
  '>[[:space:]]?/dev/sd[a-z]([^[:alnum:]]|$)' \
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
