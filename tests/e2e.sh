#!/usr/bin/env sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
project=$(mktemp -d)
trap 'rm -rf "$project"' EXIT

cp -R "$root/tests/project/." "$project/"
cd "$project"
git init -q
git config user.name 'Dev Tools Test'
git config user.email 'dev-tools@example.invalid'

composer config repositories.dev-tools \
    "{\"type\":\"path\",\"url\":\"$root\",\"options\":{\"symlink\":true}}"
composer require --dev it-nsk/dev-tools:@dev \
    --no-interaction --no-progress --no-audit --no-security-blocking

test "$(readlink -f vendor/it-nsk/dev-tools)" = "$root"
printf '#!/usr/bin/env sh\nexit 1\n' > old-pre-commit
ln -s ../../old-pre-commit .git/hooks/pre-commit
vendor/bin/dev-tools cs:fix
vendor/bin/dev-tools cs:check
vendor/bin/dev-tools phpstan

echo 'CS Fixer and PHPStan package E2E test passed.'
