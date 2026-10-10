#!/usr/bin/env bash
# setup.sh — instalación idempotente de ld-harness en PC/ambiente nuevo.
# Uso: bash ~/dev/ld-harness/setup.sh [--profile=<nombre>]
set -u

HARNESS="$HOME/dev/ld-harness"
PROFILE=""

for arg in "$@"; do
	case "$arg" in
		--profile=*) PROFILE="${arg#--profile=}" ;;
	esac
done

fail() { echo "ERROR: $1" >&2; exit 1; }
[ -d "$HARNESS" ] || fail "no existe $HARNESS (clonalo primero: git clone git@github.com:laendoor/ld-harness.git ~/dev/ld-harness)"
command -v git >/dev/null || fail "git no instalado"

link() { # link <origen> <destino>
	mkdir -p "$(dirname "$2")"
	ln -sfn "$1" "$2"
	echo "  link: $2 -> $1"
}

echo "1/4 commands → opencode (autocompletado /ld-*)"
for f in "$HARNESS"/commands/*.md; do
	link "$f" "$HOME/.config/opencode/commands/$(basename "$f")"
done

echo "2/4 skills → opencode + claude"
for d in "$HARNESS"/skills/*/ "$HARNESS"/plugins/*/skills/*/; do
	[ -d "$d" ] || continue
	name="$(basename "$d")"
	[ "$name" = "skills" ] && continue
	link "$d" "$HOME/.config/opencode/skills/$name"
	link "$d" "$HOME/.claude/skills/$name"
done

echo "3/4 plugins → opencode"
for f in "$HARNESS"/plugins/*/opencode-plugin.js; do
	[ -f "$f" ] || continue
	plugindir="$(basename "$(dirname "$f")")"
	link "$f" "$HOME/.config/opencode/plugins/$plugindir.js"
done
echo "  (claude: /plugin marketplace add laendoor/ld-harness, /plugin install ld-prosa@ld-harness)"

echo "4/4 perfil: ${PROFILE:-default}"
if [ -n "$PROFILE" ]; then
	[ -d "$HARNESS/profiles/$PROFILE" ] || fail "perfil inexistente: profiles/$PROFILE"
	echo "  overlay aplicado desde profiles/$PROFILE (ver su README)"
fi

echo "OK. Verificá con: ls -la ~/.config/opencode/skills/ ~/.claude/skills/ y /ld en opencode."
