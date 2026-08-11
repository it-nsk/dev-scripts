# dev-tools

Один репозиторий содержит две части:

- глобальный shell CLI управляет Docker, Traefik, dump и запуском команд;
- Composer-пакет `it-nsk/dev-tools` содержит PHP CS Fixer, PHPStan и Git hook.

Разработчик работает только с глобальной командой `dev-tools`.
`vendor/bin/dev-tools` вызывается автоматически внутри `app`-контейнера.

## Установка глобальной команды

Требуются Git, Docker с Compose plugin и `curl`. В `app`-образе должны быть
установлены Zsh и Oh My Zsh для рабочего пользователя контейнера.

```bash
curl -fsSL https://raw.githubusercontent.com/it-nsk/dev-scripts/dev/install.sh | sh
dev-tools version
```

По умолчанию команда устанавливается в `/usr/local/bin/dev-tools`.
Zsh completion устанавливается автоматически. После первой установки откройте
новый терминал или выполните:

```bash
exec zsh
```

После этого `dev-tools <Tab>` показывает и дополняет доступные команды.

Обновление:

```bash
dev-tools self-update
```

`self-update` обновляет одновременно CLI и его Zsh completion. В проектах для
автодополнения ничего настраивать не нужно.

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

## Поддерживаемые переменные

Проектные переменные читаются сначала из `.env`, затем из `.env.local`.
Переменная окружения процесса имеет наивысший приоритет.

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `DEV_TOOLS_COMPOSE_FILE` | `docker-compose.yml` | Рабочий Compose-файл |
| `DEV_TOOLS_COMPOSE_EXAMPLE` | `docker-compose.example.yml` | Хранимый в Git шаблон Compose |
| `DEV_TOOLS_APP_SERVICE` | `app` | Сервис приложения |
| `DEV_TOOLS_CONTAINER_SHELL` | `zsh` | Оболочка для `dev-tools sh` |
| `DEV_TOOLS_PROJECT_CONTAINER_DIR` | `*` | Путь проекта внутри контейнера для Git `safe.directory` |
| `DEV_TOOLS_PROXY_NETWORK` | `proxy` | Общая Docker-сеть reverse proxy |
| `DEV_TOOLS_TRAEFIK_CONTAINER` | `traefik` | Имя контейнера Traefik |
| `DEV_TOOLS_TRAEFIK_DIR` | `../droxy` | Каталог локального Traefik относительно проекта |
| `DEV_TOOLS_TRAEFIK_REPOSITORY` | `https://github.com/multifinger/droxy.git` | Репозиторий локального Traefik |
| `DEV_TOOLS_DOMAIN` | пусто | Основной локальный домен |
| `DEV_TOOLS_PMA_DOMAIN` | пусто | Локальный домен phpMyAdmin |
| `DEV_TOOLS_DOMAINS` | основной домен и домен phpMyAdmin | Полный список доменов для сертификата и `/etc/hosts` |
| `DEV_TOOLS_SSL_CERT` | `config/ssl/localhost.crt` | Путь к SSL-сертификату относительно проекта |
| `DEV_TOOLS_SSL_KEY` | `config/ssl/localhost.key` | Путь к приватному SSL-ключу относительно проекта |
| `DEV_TOOLS_DUMP_HOST` | пусто | SSH host для скачивания dump |
| `DEV_TOOLS_DUMP_REMOTE_PATH` | пусто | Удалённый путь или маска файлов dump |
| `DEV_TOOLS_DUMP_FILE` | `dump.sql.gz` | Локальный файл dump относительно проекта |
| `DEV_TOOLS_DB_DRIVER` | `mysql` | Драйвер БД; сейчас поддерживается MySQL |
| `DEV_TOOLS_DB_SERVICE` | `db` | Compose-сервис БД |
| `DEV_TOOLS_DB_HOST` | `localhost` | MySQL host внутри сервиса БД |
| `DEV_TOOLS_DB_PORT` | `3306` | MySQL port |
| `DEV_TOOLS_DB_NAME` | пусто | Имя локальной БД для импорта |
| `DEV_TOOLS_DB_USER` | `root` | Пользователь MySQL |
| `DEV_TOOLS_DB_PASSWORD` | `root` | Пароль MySQL |
| `DEV_TOOLS_COMPOSER_SSH_HOST` | пусто | SSH host для проверки доступа Composer к приватным пакетам |

Служебные переменные установки и запуска задаются в окружении команды, а не в
проектном `.env`:

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `DEV_TOOLS_PROJECT_DIR` | текущий каталог | Явно задаёт каталог проекта |
| `DEV_TOOLS_INSTALL_DIR` | `/usr/local/bin` | Каталог установки глобального CLI |
| `DEV_TOOLS_COMPLETION_DIR` | `/usr/local/share/zsh/site-functions` | Каталог установки Zsh completion |
| `DEV_TOOLS_UPDATE_URL` | файл из ветки `dev` | Другой источник для установки и `self-update` |
| `DEV_TOOLS_INSTALL_PATH` | путь запущенного CLI | Другой целевой файл для `self-update` |

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

`dev-tools sh` открывает login Zsh с Oh My Zsh. Вариант с одним аргументом
выполняет команду через `zsh -lc` внутри `app`:

```bash
dev-tools sh
dev-tools sh 'php bin/console cache:clear'
```

Zsh является стандартной оболочкой. Для образа, который временно её не
поддерживает, оболочку можно переопределить в `.env.local`:

```dotenv
DEV_TOOLS_CONTAINER_SHELL=sh
```

Если настроенная оболочка отсутствует в `app`, команда завершится с понятной
ошибкой. Это переопределение предназначено для миграции старых образов; новые
проекты должны устанавливать Zsh и Oh My Zsh на этапе сборки.

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
