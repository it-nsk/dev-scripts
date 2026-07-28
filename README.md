# dev-tools

Один репозиторий содержит две части:

- глобальный shell CLI управляет Docker, Traefik, dump и запуском команд;
- Composer-пакет `it-nsk/dev-tools` содержит PHP CS Fixer, PHPStan и Git hook.

Разработчик работает только с глобальной командой `dev-tools`.
`vendor/bin/dev-tools` вызывается автоматически внутри `app`-контейнера.

## Установка глобальной команды

Требуются Git, Docker с Compose plugin и `curl`.

```bash
curl -fsSL https://raw.githubusercontent.com/it-nsk/dev-scripts/dev/install.sh | sh
dev-tools version
```

По умолчанию команда устанавливается в `/usr/local/bin/dev-tools`.

Обновление:

```bash
dev-tools self-update
```

## Подключение Composer-пакета

В `composer.json` проекта:

```json
{
    "require-dev": {
        "it-nsk/dev-tools": "^0.2.0"
    }
}
```

Пакет устанавливается командой `composer install` внутри `app`-контейнера.
Отдельный VCS repository для него не нужен: релизы находятся в Packagist.

## Файлы проекта

- `.env` — существующие настройки приложения для production/test;
- `.env.local.example` — локальные настройки приложения и проекта;
- `.env.local` — локальная копия, не хранится в Git;
- `docker-compose.example.yml` — шаблон в Git;
- `docker-compose.yml` — автоматически обновляемая копия в `.gitignore`;
- Dockerfile и nginx-конфигурация проекта.

Обычно в `.env.local.example` достаточно:

```dotenv
DEV_TOOLS_DOMAIN=project.my
DEV_TOOLS_PMA_DOMAIN=pma.project.my
DEV_TOOLS_DUMP_HOST=backup
DEV_TOOLS_DUMP_REMOTE_PATH=/backup/project/*.sql.gz
DEV_TOOLS_DB_NAME=project
```

Остальные значения имеют defaults: Compose-файл `docker-compose.yml`,
сервис приложения `app`, сервис БД `db`, сеть `proxy`, MySQL root-пароль
`root`, dump `dump.sql.gz`, Traefik в соседнем каталоге `droxy`.

## Первый запуск

```bash
cd /path/to/project
dev-tools init
```

`init`:

- создает `.env.local` и обновляет Compose из example;
- проверяет Docker;
- клонирует и запускает `multifinger/droxy`, если Traefik еще не установлен;
- создает SSL-сертификат и записи `/etc/hosts`;
- скачивает dump, если настроен источник;
- собирает и запускает контейнеры;
- выполняет Composer, frontend build, cache clear и установку hook.

Для проекта, ранее работавшего на хосте:

```bash
dev-tools init --migrate-from-host
```

Старый `.env.local` сохраняется как `.env.local.host-backup`, после чего
создается Docker-конфигурация. Обычный `init` существующего Docker-проекта
сохраняет `.env.local`, но синхронизирует генерируемый Compose-файл.

## Команды

```bash
dev-tools up
dev-tools down
dev-tools build
dev-tools rebuild
dev-tools ps
dev-tools logs

dev-tools sh
dev-tools sh 'php bin/console cache:clear'

dev-tools dump:download
dev-tools dump:import

dev-tools cs:check
dev-tools cs:fix
dev-tools phpstan
dev-tools phpstan src/Foo.php src/Bar.php
dev-tools hooks:install
```

`dev-tools sh` открывает shell. Вариант с одним аргументом выполняет команду
через `sh -lc` внутри `app`.

`dump:import` удаляет и создает заново только настроенную локальную БД.

## Инструменты качества

PHP CS Fixer проверяет `src` по общей конфигурации пакета.

PHPStan автоматически использует проектный `phpstan.dist.neon`. Если файла нет,
используется общая конфигурация и каталог `src`. Переданные пути ограничивают
проверку указанными файлами.

Git hook запускает форматирование staged PHP-файлов внутри Docker и повторно
добавляет исправленные файлы в Git index.

## Разработка и тесты

```bash
composer validate --strict
composer test
composer test-docker-e2e
composer test-dev-tools-global-e2e
composer test-dev-tools-global-docker-e2e
```

Подробности реализации находятся в
[`docs/architecture.md`](docs/architecture.md) и
[`docs/quality-tools.md`](docs/quality-tools.md).
