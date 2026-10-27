#!/bin/bash
# MD040 check for format-md.sh: a nested fence must survive untouched.
# Needs prettier (VS Code extension, global or npx), like the hook itself.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

printf '%s\n' \
  '# t' '' \
  '````markdown' '```ts' 'const a = 1;' '```' '````' '' \
  '```' 'bare' '```' > "$tmp/t.md"

bash "$here/format-md.sh" "$tmp/t.md"

expected=$(printf '%s\n' \
  '# t' '' \
  '````markdown' '```ts' 'const a = 1;' '```' '````' '' \
  '```txt' 'bare' '```')
if [[ "$(cat "$tmp/t.md")" == "$expected" ]]; then
  echo "ok: nested fence kept, bare fence got txt"
else
  echo "FAIL:"; diff <(echo "$expected") "$tmp/t.md"; exit 1
fi
