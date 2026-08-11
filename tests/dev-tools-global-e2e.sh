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

CURRENT_VERSION=$(DEV_TOOLS_PROJECT_DIR="$TMP/project" "$ROOT/bin/dev-tools-global" version)
printf '%s\n' "$CURRENT_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
DEV_TOOLS_PROJECT_DIR="$TMP/project" "$ROOT/bin/dev-tools-global" help | grep -q 'dump:download'

DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_DIR="$TMP/bin" \
DEV_TOOLS_COMPLETION_DIR="$TMP/completions" \
    "$ROOT/install.sh"
"$TMP/bin/dev-tools" version | grep -qx "$CURRENT_VERSION"
"$TMP/bin/dev-tools" completion zsh >"$TMP/generated-completion"
test -f "$TMP/completions/_dev-tools"
grep -q '^#compdef dev-tools$' "$TMP/completions/_dev-tools"
cmp "$TMP/generated-completion" "$TMP/completions/_dev-tools"

DEV_TOOLS_PROJECT_DIR="$TMP/project" \
DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_PATH="$TMP/bin/dev-tools" \
DEV_TOOLS_COMPLETION_DIR="$TMP/completions" \
    "$TMP/bin/dev-tools" self-update | grep -q 'already up to date'

sed "s/DEV_TOOLS_VERSION='$CURRENT_VERSION'/DEV_TOOLS_VERSION='0.0.0'/" \
    "$ROOT/bin/dev-tools-global" >"$TMP/bin/dev-tools-old"
chmod +x "$TMP/bin/dev-tools-old"
DEV_TOOLS_UPDATE_URL="file://$ROOT/bin/dev-tools-global" \
DEV_TOOLS_INSTALL_PATH="$TMP/bin/dev-tools-old" \
DEV_TOOLS_COMPLETION_DIR="$TMP/completions" \
    "$TMP/bin/dev-tools-old" self-update | grep -q "Updated dev-tools: 0.0.0 -> $CURRENT_VERSION"
"$TMP/bin/dev-tools-old" version | grep -qx "$CURRENT_VERSION"
"$TMP/bin/dev-tools-old" completion zsh | cmp - "$TMP/completions/_dev-tools"

cat >"$TMP/bin/docker" <<'EOF'
#!/bin/sh
if [ -n "${DEV_TOOLS_DOCKER_LOG:-}" ]; then printf '%s\n' "$*" >>"$DEV_TOOLS_DOCKER_LOG"; fi
case "$*" in *"command -v"*"missing-shell"*) exit 1 ;; esac
case "$*" in
    "inspect -f {{.State.Running}}"*) printf 'true\n' ;;
    "inspect -f {{if index "*".NetworkSettings.Networks"*) printf 'true\n' ;;
esac
exit 0
EOF
chmod +x "$TMP/bin/docker"

: >"$TMP/docker.log"
PATH="$TMP/bin:$PATH" DEV_TOOLS_PROJECT_DIR="$TMP/project" \
    DEV_TOOLS_DOCKER_LOG="$TMP/docker.log" \
    "$ROOT/bin/dev-tools-global" sh
grep -Eq 'exec .*php zsh -l$' "$TMP/docker.log"

: >"$TMP/docker.log"
PATH="$TMP/bin:$PATH" DEV_TOOLS_PROJECT_DIR="$TMP/project" \
    DEV_TOOLS_DOCKER_LOG="$TMP/docker.log" \
    "$ROOT/bin/dev-tools-global" sh 'printf "zsh-command-ok"'
grep -Eq 'exec -T .*php zsh -lc printf "zsh-command-ok"$' "$TMP/docker.log"

if PATH="$TMP/bin:$PATH" DEV_TOOLS_PROJECT_DIR="$TMP/project" \
    DEV_TOOLS_CONTAINER_SHELL=missing-shell \
    "$ROOT/bin/dev-tools-global" sh 'true' 2>"$TMP/shell-error"; then
    printf 'Missing container shell was accepted\n' >&2
    exit 1
fi
grep -q "Container shell 'missing-shell' is not installed in service 'php'" \
    "$TMP/shell-error"

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
