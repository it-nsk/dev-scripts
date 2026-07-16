#!/usr/bin/env sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
project=$(mktemp -d)
trap 'rm -rf "$project"' EXIT

cp -R "$root/tests/project/." "$project/"
cd "$project"
cp .dev-tools.local.yaml .dev-tools.yaml

git init -q
git config user.name 'Dev Tools Test'
git config user.email 'dev-tools@example.invalid'

composer config repositories.dev-tools \
    "{\"type\":\"path\",\"url\":\"$root\",\"options\":{\"symlink\":true}}"
composer require --dev dev-tools/dev-tools:@dev \
    --no-interaction --no-progress --no-audit --no-security-blocking

test "$(readlink -f vendor/dev-tools/dev-tools)" = "$root"
vendor/bin/dev-tools hooks:install --mode=local
test -x .git/hooks/pre-commit

git add src
.git/hooks/pre-commit
git diff --quiet -- src
git diff --cached --check

vendor/bin/dev-tools cs:check
vendor/bin/dev-tools phpstan

echo 'CS Fixer, PHPStan and local hook E2E test passed.'
