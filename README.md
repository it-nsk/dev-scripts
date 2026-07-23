# Dev Tools

Общие PHP CS Fixer, PHPStan и Git hooks для PHP/Symfony-проектов. Пакет хранит
логику инструментов в одном месте, а каждый проект задаёт только пути и режим
запуска в `.dev-tools.yaml`.

## Возможности

- единый набор правил PHP CS Fixer;
- общая конфигурация PHPStan для Symfony и Doctrine;
- запуск инструментов локально или через Docker Compose;
- pre-commit hook, исправляющий только staged PHP-файлы;
- готовые Makefile-цели без копирования команд между проектами.

## Требования

- PHP 8.3 или новее;
- Composer 2;
- Git — для установки и выполнения hook;
- Docker Compose — только для Docker-режима.

## Установка

```bash
composer require --dev it-nsk/dev-tools
```

Создайте `.dev-tools.yaml`:

```yaml
cs_fixer:
    mode: local
    paths: [src]

phpstan:
    mode: local
    paths: [src]

hooks:
    mode: local
```

Проверьте подключение:

```bash
vendor/bin/dev-tools help
vendor/bin/dev-tools cs:check
vendor/bin/dev-tools phpstan
```

## Docker

Инструменты можно запускать в сервисе приложения:

```yaml
cs_fixer:
    mode: docker
    paths: [src]

phpstan:
    mode: docker
    paths: [src]

hooks:
    mode: docker

docker:
    command: [docker, compose]
    service: app
    env_files: [.env, .env.local]
```

Режим из YAML можно переопределить для одного запуска:

```bash
vendor/bin/dev-tools cs:check --mode=local
vendor/bin/dev-tools cs:check --mode=docker
vendor/bin/dev-tools phpstan --mode=local
vendor/bin/dev-tools phpstan --mode=docker
```

## Команды

```text
dev-tools cs:check [--mode=local|docker]
dev-tools cs:fix [--mode=local|docker]
dev-tools phpstan [path...] [--mode=local|docker]
dev-tools hooks:install [--mode=local|docker]
```

`cs:check` только показывает нарушения. `cs:fix` изменяет настроенные файлы.

## Git hook

```bash
vendor/bin/dev-tools hooks:install --mode=local
# либо
vendor/bin/dev-tools hooks:install --mode=docker
```

Hook копируется в `.git/hooks/pre-commit`, форматирует staged PHP-файлы и снова
добавляет их в Git index. Если PHP-файл добавлен частично, после форматирования
он станет полностью staged.

## Makefile

Подключите общие цели:

```make
-include vendor/it-nsk/dev-tools/make/dev-tools.mk
```

Доступные команды:

```bash
make cs-check
make cs-check-local
make cs-check-docker
make cs-fix
make cs-fix-local
make cs-fix-docker
make phpstan
make phpstan-local
make phpstan-docker
make phpstan-files FILES="src/Foo.php src/Bar.php"
make hooks-local
make hooks-docker
```

## Проектная конфигурация PHPStan

Для baseline или проектных исключений укажите:

```yaml
phpstan:
    config: phpstan.dist.neon
```

И подключите общий конфиг:

```neon
includes:
    - vendor/it-nsk/dev-tools/config/phpstan.neon
    - phpstan-baseline.neon
```

Не подключайте расширения Symfony и Doctrine повторно: они уже входят в общий
конфиг.

## Разработка

```bash
composer install
composer test
composer test-docker-e2e
composer test-bgt-dev-e2e
composer test-bgt-dev-docker-e2e
```

Local E2E создаёт временный Composer/Git-проект и проверяет fixer, PHPStan и
hook. Docker E2E повторяет сценарий в PHP 8.3-контейнере и удаляет созданные
ресурсы после завершения.

Подробности:

- [интеграция и настройки](docs/quality-tools.md);
- [архитектура и назначение файлов](docs/architecture.md);

## Глобальный Docker CLI

`bgt-dev` устанавливается один раз и доступен до запуска Docker и
`composer install`:

```bash
curl -fsSL https://raw.githubusercontent.com/it-nsk/dev-scripts/ITNSK-37-docker-migration/install.sh | sh
```

По умолчанию бинарник устанавливается в `/usr/local/bin`. Общие команды:

```bash
bgt-dev init
bgt-dev up
bgt-dev down
bgt-dev build
bgt-dev logs
bgt-dev shell
bgt-dev dump:download
bgt-dev dump:import
bgt-dev cs:check
bgt-dev phpstan
bgt-dev hooks:install
bgt-dev migrate
bgt-dev self-update
```

Уникальные настройки проекта задаются переменными `BGT_*` в `.env` и при
необходимости переопределяются в `.env.local`. Dockerfile, конфигурация Nginx
и `docker-compose.example.yml` остаются в репозитории проекта.

## Лицензия

[MIT](LICENSE)
