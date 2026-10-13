#!/bin/bash
# ld-format — formatea archivos .md: Prettier + regla MD040 (`txt` en fences
# sin lenguaje).
#
# Doble consumidor con una sola fuente de verdad:
#   - opencode: plugins/ld-format/opencode-plugin.js lo invoca con $1 = path.
#   - Claude Code: hooks/hooks.json (PostToolUse Write|Edit) lo invoca sin
#     args; el path sale del JSON en stdin (.tool_input.file_path).
#
# Idempotente y silencioso: si no hay prettier disponible igual aplica MD040;
# si el archivo no es .md, no hace nada.

if [ -n "$1" ]; then
  FILE_PATH="$1"
else
  FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if [[ "$FILE_PATH" == *.md ]]; then
  # 1. Prettier: el de la extensión de VS Code primero (misma versión que el
  #    save del editor, sin diff al guardar a mano), después global, después npx.
  VSCODE_PRETTIER=$(ls -d "$HOME"/.vscode/extensions/esbenp.prettier-vscode-*/node_modules/prettier/bin/prettier.cjs 2>/dev/null | tail -1)
  if [[ -n "$VSCODE_PRETTIER" ]] && command -v node &>/dev/null; then
    node "$VSCODE_PRETTIER" --write "$FILE_PATH" 2>/dev/null
  elif command -v prettier &>/dev/null; then
    prettier --write "$FILE_PATH" 2>/dev/null
  else
    npx --yes prettier --write "$FILE_PATH" 2>/dev/null
  fi

  # 2. MD040: `txt` en fences de apertura sin lenguaje. Se trackea estado
  #    (dentro/fuera) para no tocar el fence de cierre.
  awk '
    BEGIN { in_block = 0 }
    /^```/ {
      if (!in_block) {
        in_block = 1
        if ($0 == "```") { print "```txt"; next }
      } else {
        in_block = 0
      }
    }
    { print }
  ' "$FILE_PATH" > "${FILE_PATH}.tmp" && mv "${FILE_PATH}.tmp" "$FILE_PATH"
fi

exit 0
