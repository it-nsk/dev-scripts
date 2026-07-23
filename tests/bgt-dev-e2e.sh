#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$TMP/project" "$TMP/bin"
cat >"$TMP/project/.env" <<'EOF'
BGT_COMPOSE_FILE=compose.yaml
BGT_COMPOSE_EXAMPLE=compose.example.yaml
BGT_APP_SERVICE=php
BGT_DOMAINS=example.my pma.example.my
EOF
cat >"$TMP/project/compose.example.yaml" <<'EOF'
services:
  php:
    image: php:8.3-cli
EOF

BGT_PROJECT_DIR="$TMP/project" "$ROOT/bin/bgt-dev" version | grep -qx '0.2.0'
BGT_PROJECT_DIR="$TMP/project" "$ROOT/bin/bgt-dev" help | grep -q 'dump:download'

BGT_DEV_UPDATE_URL="file://$ROOT/bin/bgt-dev" \
BGT_DEV_INSTALL_DIR="$TMP/bin" \
    "$ROOT/install.sh"
"$TMP/bin/bgt-dev" version | grep -qx '0.2.0'

BGT_PROJECT_DIR="$TMP/project" \
BGT_DEV_UPDATE_URL="file://$ROOT/bin/bgt-dev" \
BGT_DEV_INSTALL_PATH="$TMP/bin/bgt-dev" \
    "$TMP/bin/bgt-dev" self-update | grep -q 'already up to date'

sed "s/BGT_DEV_VERSION='0.2.0'/BGT_DEV_VERSION='0.1.0'/" \
    "$ROOT/bin/bgt-dev" >"$TMP/bin/bgt-dev-old"
chmod +x "$TMP/bin/bgt-dev-old"
BGT_DEV_UPDATE_URL="file://$ROOT/bin/bgt-dev" \
BGT_DEV_INSTALL_PATH="$TMP/bin/bgt-dev-old" \
    "$TMP/bin/bgt-dev-old" self-update | grep -q 'Updated bgt-dev: 0.1.0 -> 0.2.0'
"$TMP/bin/bgt-dev-old" version | grep -qx '0.2.0'

printf 'Global bgt-dev install and self-update E2E test passed.\n'
