#!/usr/bin/env bash
# PreToolUse hook: hard-block any `git push` Claude tries to run.
# Push is the user's job (cheap alias `ggpush`); sending to the cloud can
# affect teammates, so Claude is never allowed to push.
set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

# Match `git [global-flags...] push` anywhere in a (possibly compound) command.
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(`[:space:]])git([[:space:]]+-{1,2}[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "git push is blocked for Claude by user policy. The user runs pushes themselves (ggpush). Surface the command for the user to run instead."
    }
  }'
  exit 0
fi
