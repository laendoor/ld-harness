#!/usr/bin/env bash
# PreToolUse hook: Claude commits only on a ticket branch. A local commit there is undone with
# git reset; main is protected, and push is already blocked by block-git-push.sh.
set -euo pipefail

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

grep -Eq '(^|[;&|(`[:space:]])git([[:space:]]+-{1,2}[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+(commit|merge|cherry-pick|revert|am)([[:space:]]|$)' <<<"$cmd" || exit 0

# `git -C <path>` targets another checkout (a ticket living in a sibling repo): judge that one's branch.
# The path is read as text, so a shell variable in it is not expanded and the command is denied.
repo="$(grep -Eo 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' <<<"$cmd" | head -1 | awk '{print $3}' | tr -d "'\"" || true)"
# Without -C, a leading `cd <path> && git commit` moves the commit to that checkout: judge it, not the cwd.
[ -n "$repo" ] || repo="$(grep -Eo '(^|[;&|(])[[:space:]]*cd[[:space:]]+[^[:space:];&|)]+' <<<"$cmd" | head -1 | awk '{print $NF}' | tr -d "'\"" || true)"
case "$repo" in "~"|"~/"*) repo="$HOME${repo#\~}" ;; esac
case "$repo" in "") repo="${cwd:-.}" ;; /*) ;; *) repo="${cwd:-.}/$repo" ;; esac
branch="$(git -C "$repo" symbolic-ref --short -q HEAD || echo DETACHED)"
case "$branch" in main|master|DETACHED) ;; *) exit 0 ;; esac

jq -n --arg b "$branch" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Commit on " + $b + " is blocked for Claude: commit only on the ticket branch.")
  }
}'
