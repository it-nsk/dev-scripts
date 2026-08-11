#!/usr/bin/env sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
project=$(mktemp -d)
export COMPOSE_PROJECT_NAME="dev-tools-e2e-$$"
uid=$(id -u)
gid=$(id -g)

cleanup() {
    cd "$project"
    docker compose -f compose.yaml exec -T app chown -R "$uid:$gid" /app >/dev/null 2>&1 || true
    docker compose -f compose.yaml down --rmi local -v --remove-orphans >/dev/null 2>&1 || true
    rm -rf "$project"
}
trap cleanup EXIT INT TERM

cp -R "$root/tests/project/." "$project/"
cd "$project"
: > .env
git init -q
git config user.name 'Dev Tools Test'
git config user.email 'dev-tools@example.invalid'

composer config repositories.dev-tools \
    "{\"type\":\"path\",\"url\":\"$root\",\"options\":{\"symlink\":false}}"
composer require --dev it-nsk/dev-tools:@dev \
    --no-interaction --no-progress --no-audit --no-security-blocking

test -d vendor/it-nsk/dev-tools
test ! -L vendor/it-nsk/dev-tools
docker compose -f compose.yaml build
docker compose -f compose.yaml up -d --wait
test -n "$(docker compose -f compose.yaml ps --status running -q app)"

docker compose -f compose.yaml exec -T \
    -e GIT_CONFIG_COUNT=1 \
    -e GIT_CONFIG_KEY_0=safe.directory \
    -e GIT_CONFIG_VALUE_0=/app \
    app vendor/bin/dev-tools hooks:install
git add src
.git/hooks/pre-commit
git diff --quiet -- src
git diff --cached --check
vendor/bin/dev-tools cs:check
vendor/bin/dev-tools phpstan

echo 'CS Fixer, PHPStan and Docker hook E2E test passed.'
