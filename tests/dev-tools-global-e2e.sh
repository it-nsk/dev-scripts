#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$TMP/project" "$TMP/bin"
cat >"$TMP/project/.env" <<'EOF'
DEV_TOOLS_COMPOSE_FILE=compose.yaml
DEV_TOOLS_COMPOSE_EXAMPLE=compose.example.yaml
DEV_TOOLS_APP_SERVICE=php
DEV_TOOLS_DOMAINS=example.my pma.example.my
EOF
cat >"$TMP/project/compose.example.yaml" <<'EOF'
services:
  php:
    image: php:8.3-cli
EOF

DEV_TOOLS_PROJECT_DIR="$TMP/project" "$ROOT/bin/dev-tools-global" version | grep -qx '0.3.0'
DEV_TOOLS_PROJECT_DIR="$TMP/project" "$ROOT/bin/dev-tools-global" help | grep -q 'dump:download'

DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_DIR="$TMP/bin" \
    "$ROOT/install.sh"
"$TMP/bin/dev-tools" version | grep -qx '0.3.0'

DEV_TOOLS_PROJECT_DIR="$TMP/project" \
DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_PATH="$TMP/bin/dev-tools" \
    "$TMP/bin/dev-tools" self-update | grep -q 'already up to date'

sed "s/DEV_TOOLS_VERSION='0.3.0'/DEV_TOOLS_VERSION='0.2.0'/" \
    "$ROOT/bin/dev-tools-global" >"$TMP/bin/dev-tools-old"
chmod +x "$TMP/bin/dev-tools-old"
DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_PATH="$TMP/bin/dev-tools-old" \
    "$TMP/bin/dev-tools-old" self-update | grep -q 'Updated dev-tools: 0.2.0 -> 0.3.0'
"$TMP/bin/dev-tools-old" version | grep -qx '0.3.0'

printf 'Global dev-tools install and self-update E2E test passed.\n'
