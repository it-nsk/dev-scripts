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
BGT_COMPOSE_FILE=compose.yaml
BGT_COMPOSE_EXAMPLE=compose.example.yaml
BGT_DB_DRIVER=mysql
BGT_DB_SERVICE=db
BGT_DB_HOST=localhost
BGT_DB_PORT=3306
BGT_DB_NAME=dev_tools_e2e
BGT_DB_USER=root
BGT_DB_PASSWORD=root
BGT_DUMP_FILE=dump.sql.gz
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
DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" dump:import

result=$(DEV_TOOLS_PROJECT_DIR="$TMP" "$ROOT/bin/dev-tools-global" compose exec -T \
    db mysql -uroot --password=root -N \
    -e 'SELECT value FROM dev_tools_e2e.smoke_test WHERE id = 1')

[ "$result" = 'dump-import-ok' ] || {
    printf 'Unexpected dump value: %s\n' "$result" >&2
    exit 1
}

printf 'Global dev-tools Docker lifecycle and dump import E2E test passed.\n'
