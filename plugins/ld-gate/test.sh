#!/usr/bin/env bash
# Runs the ld-gate Claude hooks against fixed payloads. Usage: bash plugins/ld-gate/test.sh
# Lives in a file because a command whose text holds `git … commit` trips the hook itself.
H="$(cd "$(dirname "$0")" && pwd)/hooks"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
git init -q -b main "$T/main"
git init -q -b task/x "$T/task"
fails=0

check() { # check <hook> <allow|deny> <cwd> <command>
  out=$(jq -n --arg c "$4" --arg d "$3" '{tool_input:{command:$c},cwd:$d}' | "$H/$1")
  got=allow; grep -q '"deny"' <<<"$out" && got=deny
  [ "$got" = "$2" ] || { fails=$((fails + 1)); echo "FAIL $1 expected $2: $4"; }
}

check block-commit-on-main.sh allow "$T/task" "git commit -m x"
check block-commit-on-main.sh deny  "$T/main" "git commit -m x"
check block-commit-on-main.sh deny  "$T/task" "cd $T/main && git commit -m x"
check block-commit-on-main.sh deny  "$T/task" "cd $T/main; git add . && git commit -m x"
check block-commit-on-main.sh allow "$T/main" "cd $T/task && git commit -m x"
check block-commit-on-main.sh deny  "$T/task" "git -C $T/main commit -m x"
check block-commit-on-main.sh allow "$T/main" "git -C $T/task commit -m x"
check block-commit-on-main.sh allow "$T/main" "git status"
check block-git-push.sh       deny  "$T/task" "git push -u origin x"
check block-git-push.sh       deny  "$T/task" "git -C $T/main push"
check block-git-push.sh       allow "$T/task" "git pull --ff-only"
check block-catastrophic.sh   deny  "$T/task" "rm -rf /"
check block-catastrophic.sh   deny  "$T/task" "rm -rf / && echo"
check block-catastrophic.sh   deny  "$T/task" "sudo rm -rf /*"
check block-catastrophic.sh   allow "$T/task" "rm -rf /tmp/x"
check block-catastrophic.sh   deny  "$T/task" ":(){ :|:& };:"
check block-catastrophic.sh   deny  "$T/task" "mkfs.ext4 /dev/disk2"
check block-catastrophic.sh   deny  "$T/task" "echo x > /dev/sda"
check block-catastrophic.sh   allow "$T/task" "ls /dev/sda"
check block-catastrophic.sh   deny  "$T/task" "make alembic-downgrade REV=base"
check block-catastrophic.sh   deny  "$T/task" "cd apps/api && uv run alembic downgrade -1"
check block-catastrophic.sh   allow "$T/task" "make alembic-upgrade && make alembic-check"
check block-catastrophic.sh   deny  "$T/task" "dropdb academika"
check block-catastrophic.sh   allow "$T/task" "psql -c 'SELECT 1'"
check block-catastrophic.sh   deny  "$T/task" "psql -c 'DROP DATABASE academika'"
check block-catastrophic.sh   deny  "$T/task" "psql -c 'drop schema public cascade'"
check block-catastrophic.sh   deny  "$T/task" "psql -c 'TRUNCATE cursadas'"
check block-catastrophic.sh   deny  "$T/task" "psql -c 'delete from alumnos'"
check block-catastrophic.sh   deny  "$T/task" "psql -q -c 'select 1' -c 'drop table cursadas'"
check block-catastrophic.sh   deny  "$T/task" $'docker compose exec -T postgres psql -U x -d y <<\'SQL\'\nTRUNCATE cursadas;\nSQL'
check block-catastrophic.sh   allow "$T/task" "grep -rn truncate docs/"
check block-catastrophic.sh   allow "$T/task" "git commit -m 'add truncate helper'"
check block-catastrophic.sh   allow "$T/task" "rg 'drop table' apps/api"
check block-catastrophic.sh   deny  "$T/task" "docker compose down -v"
check block-catastrophic.sh   deny  "$T/task" "docker volume rm academika_pg_data"
check block-catastrophic.sh   allow "$T/task" "docker compose down"
check block-catastrophic.sh   allow "$T/task" "docker compose up -d postgres"
check block-catastrophic.sh   deny  "$T/task" "docker compose -f compose.yaml down -v"
check block-catastrophic.sh   allow "$T/task" "docker run --rm -v /tmp/x:/x alpine true"
check block-catastrophic.sh   deny  "$T/task" "pg_restore --clean -d academika dump.sql"

[ "$fails" -eq 0 ] && echo "ld-gate: all checks pass" || exit 1
