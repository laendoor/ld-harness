#!/usr/bin/env bash
# PreToolUse hook: deny the shell patterns nobody runs on purpose. Same list as
# opencode-plugin.js — if one changes, change the other.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"

# ERE, not PCRE: macOS grep has no -P.
for re in \
  'rm[[:space:]]+-rf?[[:space:]]+/([[:space:];&|]|$)' \
  'rm[[:space:]]+-rf?[[:space:]]+/\*' \
  'mkfs(\.|[[:space:]]|$)' \
  ':[[:space:]]?\(\)[[:space:]]?\{[[:space:]]?:[[:space:]]?\|[[:space:]]?:[[:space:]]?&[[:space:]]?\}[[:space:]]?;' \
  '>[[:space:]]?/dev/sd[a-z]([^[:alnum:]]|$)'; do
  if grep -Eq -- "$re" <<<"$cmd"; then
    jq -n --arg re "$re" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("[ld-gate] blocked by catastrophic pattern " + $re)
      }
    }'
    exit 0
  fi
done
