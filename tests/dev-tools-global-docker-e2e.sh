#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)

cleanup()
{
    DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" compose down -v --remove-orphans >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT HUP INT TERM

cat >"$TMP/.env" <<'EOF'
DEV_TOOLS_COMPOSE_FILE=compose.yaml
DEV_TOOLS_COMPOSE_EXAMPLE=compose.example.yaml
DEV_TOOLS_APP_SERVICE=db
DEV_TOOLS_DB_DRIVER=mysql
DEV_TOOLS_DB_SERVICE=db
DEV_TOOLS_DB_HOST=localhost
DEV_TOOLS_DB_PORT=3306
DEV_TOOLS_DB_NAME=dev_tools_e2e
DEV_TOOLS_DB_USER=root
DEV_TOOLS_DB_PASSWORD=root
DEV_TOOLS_DUMP_FILE=dump.sql.gz
EOF

cat >"$TMP/.env.local.example" <<'EOF'
LOCAL_ENV_CREATED=true
EOF

cat >"$TMP/compose.example.yaml" <<'EOF'
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
    healthcheck:
      test: ["CMD-SHELL", "mysql -h localhost -uroot -proot -e 'SELECT 1'"]
      interval: 1s
      timeout: 3s
      retries: 30
volumes: {}
EOF

printf '%s\n' \
    'CREATE TABLE smoke_test (id INT PRIMARY KEY, value VARCHAR(32) NOT NULL);' \
    "INSERT INTO smoke_test VALUES (1, 'dump-import-ok');" \
    | gzip >"$TMP/dump.sql.gz"

DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" compose up -d --wait db
[ -f "$TMP/.env.local" ]
grep -qx 'LOCAL_ENV_CREATED=true' "$TMP/.env.local"
DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" dump:import

result=$(DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" compose exec -T \
    db mysql -uroot --password=root -N \
    -e 'SELECT value FROM dev_tools_e2e.smoke_test WHERE id = 1')

[ "$result" = 'dump-import-ok' ] || {
    printf 'Unexpected dump value: %s\n' "$result" >&2
    exit 1
}

printf 'not-a-gzip-dump\n' >"$TMP/dump.sql.gz"
if DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" dump:import >/dev/null 2>&1; then
    printf 'Invalid dump was accepted\n' >&2
    exit 1
fi
result=$(DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" compose exec -T \
    db mysql -uroot --password=root -N \
    -e 'SELECT value FROM dev_tools_e2e.smoke_test WHERE id = 1')
[ "$result" = 'dump-import-ok' ] || {
    printf 'Database changed after invalid dump: %s\n' "$result" >&2
    exit 1
}

result=$(DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" sh \
    'printf "shell-command-ok"')
[ "$result" = 'shell-command-ok' ]

printf 'Global dev-tools Docker lifecycle and dump import E2E test passed.\n'
