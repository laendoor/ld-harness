#!/usr/bin/env bash
# setup.sh — instalación idempotente de ld-harness en PC/ambiente nuevo.
# Uso: bash ~/dev/ld-harness/setup.sh
set -u

HARNESS="$HOME/dev/ld-harness"

fail() { echo "ERROR: $1" >&2; exit 1; }
[ -d "$HARNESS" ] || fail "no existe $HARNESS (clonalo primero: git clone git@github.com:laendoor/ld-harness.git ~/dev/ld-harness)"
command -v git >/dev/null || fail "git no instalado"

link() { # link <origen> <destino>
	mkdir -p "$(dirname "$2")"
	ln -sfn "$1" "$2"
	echo "  link: $2 -> $1"
}

echo "1/5 commands → opencode (autocompletado /ld-*) + claude (solo los sin skill gemelo)"
for f in "$HARNESS"/commands/*.md; do
	link "$f" "$HOME/.config/opencode/commands/$(basename "$f")"
	# En Claude un skill ya es /comando: linkear el gemelo duplicaría el nombre.
	[ -d "$HARNESS/skills/$(basename "$f" .md)" ] || link "$f" "$HOME/.claude/commands/$(basename "$f")"
done

echo "2/5 skills → opencode + claude (los de plugins, solo opencode)"
for d in "$HARNESS"/skills/*/ "$HARNESS"/plugins/*/skills/*/; do
	[ -d "$d" ] || continue
	name="$(basename "$d")"
	[ "$name" = "skills" ] && continue
	link "$d" "$HOME/.config/opencode/skills/$name"
	# En Claude el skill de un plugin ya llega por el plugin (<plugin>:<skill>).
	case "$d" in "$HARNESS"/plugins/*) ;; *) link "$d" "$HOME/.claude/skills/$name" ;; esac
done

echo "3/5 plugins → opencode"
for f in "$HARNESS"/plugins/*/opencode-plugin.js; do
	[ -f "$f" ] || continue
	plugindir="$(basename "$(dirname "$f")")"
	link "$f" "$HOME/.config/opencode/plugins/$plugindir.js"
done
echo "  (claude: claude plugin marketplace add ~/dev/ld-harness && claude plugin install ld-prosa@ld-harness && claude plugin install ld-format@ld-harness)"

echo "4/5 formatters default → opencode global (solo agrega, nunca pisa)"
# ld-format: cada proyecto puede pisar con su propio `formatter` en opencode.json.
python3 - "$HOME/.config/opencode/opencode.json" <<'EOF' || true
import json, os, sys
path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try:
        cfg = json.load(open(path))
    except Exception:
        print("  SKIP: opencode.json global no es JSON válido (¿JSONC?) — agregá \"formatter\" a mano")
        sys.exit(0)
if "formatter" not in cfg:
    cfg["formatter"] = True
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(cfg, open(path, "w"), indent=2)
    open(path, "a").write("\n")
    print("  formatter:true agregado al opencode.json global")
else:
    print("  formatter ya definido en global, no se toca")
EOF

echo "5/5 purga de symlinks colgados (renombres viejos)"
for d in "$HOME/.config/opencode/commands" "$HOME/.config/opencode/skills" \
	"$HOME/.config/opencode/plugins" "$HOME/.claude/skills" "$HOME/.claude/commands"; do
	[ -d "$d" ] || continue
	find "$d" -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
done

echo "OK. Verificá con: ls -la ~/.config/opencode/skills/ ~/.claude/skills/ ~/.claude/commands/"
