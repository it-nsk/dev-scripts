# PHP CS Fixer, PHPStan и Git hooks

## Конфигурация проекта

Минимальный `.dev-tools.yaml`:

```yaml
cs_fixer:
    mode: local
    paths: [src]
    exclude: []

phpstan:
    mode: local
    paths: [src]
    memory_limit: 1G

hooks:
    mode: local
```

Для Docker задайте `mode: docker` и добавьте:

```yaml
docker:
    command: [docker, compose]
    service: app
    env_files: [.env, .env.local]
```

В app-контейнере должны быть доступны PHP, Git, `vendor` и смонтированный
проект вместе с `.git`.

## PHP CS Fixer

```bash
make cs-check # выводит diff и ничего не изменяет
make cs-fix   # форматирует файлы
make cs-check-local
make cs-check-docker
```

Общие правила находятся в
`vendor/dev-tools/dev-tools/config/php-cs-fixer.php`. Пути и исключения задаются
через `cs_fixer.paths` и `cs_fixer.exclude`.

На legacy-проекте сначала выполните `make cs-check`. Массовое форматирование
лучше вынести в отдельный commit без изменений логики.

## PHPStan

```bash
make phpstan
make phpstan-local
make phpstan-docker
make phpstan-files FILES="src/Foo.php src/Bar.php"
```

Если проекту нужен baseline или собственные правила, укажите:

```yaml
phpstan:
    config: phpstan.dist.neon
```

А в `phpstan.dist.neon` подключите общий конфиг:

```neon
includes:
    - vendor/dev-tools/dev-tools/config/phpstan.neon
    - phpstan-baseline.neon
```

## Git hook

```bash
make hooks-local
# либо
make hooks-docker
```

Команда копирует `.git/hooks/pre-commit`, а не создаёт symlink на `vendor`.
Hook выбирает staged PHP-файлы, исправляет их и повторно добавляет в Git index.
PHP CS Fixer форматирует файл целиком, поэтому частично staged PHP-файл после
hook станет полностью staged.

Проверка без создания commit:

```bash
git add src/SomeFile.php
.git/hooks/pre-commit
git diff --cached --check
git diff --cached
```

## Локальная интеграция через path repository

Если библиотека находится рядом с проектом:

```text
/path/to/dev-tools
/path/to/your-project
```

в каталоге проекта выполните:

```bash
composer config repositories.dev-tools \
  '{"type":"path","url":"../dev-scripts","options":{"symlink":true}}'
composer require --dev dev-tools/dev-tools:@dev
```

Проверьте подключение:

```bash
readlink -f vendor/dev-tools/dev-tools
vendor/bin/dev-tools help
make cs-check
make phpstan
```

`readlink` должен вывести путь локального checkout библиотеки. `cs-check`
возвращает ненулевой код, если нашёл нарушения — это нормальный результат до
запуска `cs-fix`.
