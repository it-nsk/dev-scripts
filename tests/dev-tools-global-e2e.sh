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

cat >"$TMP/bin/docker" <<'EOF'
#!/bin/sh
case "$*" in
    "inspect -f {{.State.Running}}"*) printf 'true\n' ;;
    "inspect -f {{if index "*".NetworkSettings.Networks"*) printf 'true\n' ;;
esac
exit 0
EOF
chmod +x "$TMP/bin/docker"

printf 'OLD_COMPOSE=true\n' >"$TMP/project/compose.yaml"
PATH="$TMP/bin:$PATH" DEV_TOOLS_PROJECT_DIR="$TMP/project" \
    "$ROOT/bin/dev-tools-global" compose config
cmp "$TMP/project/compose.example.yaml" "$TMP/project/compose.yaml"

printf 'HOST_DATABASE=true\n' >"$TMP/project/.env.local"
printf 'DOCKER_DATABASE=true\n' >"$TMP/project/.env.local.example"
PATH="$TMP/bin:$PATH" DEV_TOOLS_PROJECT_DIR="$TMP/project" \
    DEV_TOOLS_DOMAIN=localhost DEV_TOOLS_DOMAINS=localhost \
    "$ROOT/bin/dev-tools-global" init --migrate-from-host
grep -qx 'HOST_DATABASE=true' "$TMP/project/.env.local.host-backup"
grep -qx 'DOCKER_DATABASE=true' "$TMP/project/.env.local"

printf 'Global dev-tools install and self-update E2E test passed.\n'
