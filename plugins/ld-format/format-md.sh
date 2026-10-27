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
#
# Un repo con config de formato propia es dueño de su formato y no se toca:
# reformatear el archivo entero en cada Edit le mete diffs ajenos, y Prettier
# reescribe `_` intraword como énfasis (MCP_URL → MCP*URL en un CHANGELOG).

if [ -n "$1" ]; then
  FILE_PATH="$1"
else
  FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

owns_formatting() {
  local dir root
  dir=$(cd "$(dirname "$1")" 2>/dev/null && pwd) || return 1
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
  while :; do
    for f in biome.json biome.jsonc .prettierrc .prettierrc.json .prettierrc.yaml .prettierrc.yml \
      .prettierrc.js .prettierrc.cjs .prettierrc.mjs prettier.config.js prettier.config.cjs \
      prettier.config.mjs dprint.json .editorconfig; do
      [[ -e "$dir/$f" ]] && return 0
    done
    [[ "$dir" == "$root" || "$dir" == "/" ]] && return 1
    dir=$(dirname "$dir")
  done
}

if [[ "$FILE_PATH" == *.md ]] && ! owns_formatting "$FILE_PATH"; then
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

  # 2. MD040: `txt` en fences de apertura sin lenguaje. Cierra solo un fence de
  #    al menos el largo del que abrió y sin lenguaje: un ``` dentro de un ````
  #    es contenido, y tratarlo como cierre rompe los bloques anidados.
  awk '
    match($0, /^```+/) {
      n = RLENGTH; info = substr($0, n + 1)
      if (!open) {
        open = n
        if (info == "") { print substr($0, 1, n) "txt"; next }
      } else if (n >= open && info ~ /^[ \t]*$/) {
        open = 0
      }
    }
    { print }
  ' "$FILE_PATH" > "${FILE_PATH}.tmp" && mv "${FILE_PATH}.tmp" "$FILE_PATH"
fi

exit 0
