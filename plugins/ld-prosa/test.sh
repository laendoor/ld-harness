#!/usr/bin/env bash
# Runs the ld-prosa hooks against fixed configs and checks the skill budget and
# the 10,000-character cap Claude Code puts on one hook's stdout.
# Usage: bash plugins/ld-prosa/test.sh
P="$(cd "$(dirname "$0")" && pwd)"
H="$P/hooks"
R="$P/skills/ld-prosa"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home/.config/ld-harness" "$T/proj"
fails=0

fail() { fails=$((fails + 1)); echo "FAIL: $1"; }

run() { (cd "$T/proj" && HOME="$T/home" node "$H/ld-prosa-activate.js" "$1"); }

# Default: es-AR chat, en artifacts. Core and references ship as two commands.
core=$(run core)
refs=$(run references)
grep -q "Name who does what" <<<"$core" || fail "core missing from the injection"
grep -q "postures in full" <<<"$core" && fail "core carries posturas"
grep -q "Prosa en español" <<<"$core" && fail "core carries a language reference"
grep -q "skill files in $R" <<<"$core" || fail "core does not name the skill dir"
grep -q "Prosa en español" <<<"$refs" || fail "es reference missing on es-AR chat"
grep -q "English prose" <<<"$refs" || fail "en reference missing on en artifacts"
grep -q "postures in full" <<<"$refs" && fail "posturas.md injected; it is on demand"

# Each command must fit the cap on its own; together they do not.
for part in core references; do
	bytes=$(run "$part" | wc -c | tr -d ' ')
	[ "$bytes" -le 10000 ] || fail "$part is $bytes chars (cap 10000)"
done

# User config narrows to English.
printf 'LD_PROSA_CHAT=en\nLD_PROSA_ARTIFACTS=en\n' >"$T/home/.config/ld-harness/config.env"
refs=$(run references)
grep -q "English prose" <<<"$refs" || fail "en reference missing with en/en"
grep -q "Prosa en español" <<<"$refs" && fail "es reference leaked with en/en"

# Quotes are dotenv syntax, not part of the value.
printf 'LD_PROSA_CHAT="en"\nLD_PROSA_ARTIFACTS="en"\n' >"$T/home/.config/ld-harness/config.env"
refs=$(run references)
grep -q "English prose" <<<"$refs" || fail "quoted value dropped the en reference"
grep -q "Prosa en español" <<<"$refs" && fail "quoted value leaked es"

# Project file beats the user file.
printf 'LD_PROSA_CHAT=es\nLD_PROSA_ARTIFACTS=es\n' >"$T/proj/.ld-harness.env"
refs=$(run references)
grep -q "Prosa en español" <<<"$refs" || fail "project override ignored"
grep -q "English prose" <<<"$refs" && fail "en reference leaked after override"

# The core stays a core: body lines, frontmatter excluded.
body=$(awk 'BEGIN { fm = 0 } /^---$/ { fm++; next } fm >= 2' "$R/SKILL.md" | wc -l | tr -d ' ')
[ "$body" -le 110 ] || fail "core body is $body lines (budget 110)"

# Every reference the core names exists.
for ref in $(grep -o 'references/[a-z]*\.md' "$R/SKILL.md" | sort -u); do
	[ -f "$R/$ref" ] || fail "missing $ref named in the core"
done

# The per-turn nudge lives once and both engines read it from there.
grep -q "Name who does what" "$H/nudge.js" || fail "nudge lost the rule"
grep -q "require('./nudge')" "$H/ld-prosa-reminder.js" || fail "claude nudge bypasses nudge.js"
grep -q 'from "./hooks/nudge.js"' "$P/opencode-plugin.js" || fail "opencode nudge bypasses nudge.js"

if [ "$fails" -eq 0 ]; then
	echo "ld-prosa: all checks pass"
else
	exit 1
fi
