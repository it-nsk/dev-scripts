# Архитектура

```text
GitHub it-nsk/dev-scripts
        |
        +-- install.sh -> /usr/local/bin/dev-tools
        |                    |
        |                    +-> Docker / Traefik / dump
        |                    +-> docker compose exec app
        |                                      |
        +-- Composer package <-----------------+
              |
              +-> PHP CS Fixer
              +-> PHPStan
              +-> Git hook
```

## Глобальный shell CLI

`bin/dev-tools-global` работает до запуска контейнеров и Composer. Он отвечает
за lifecycle Docker, установку Traefik, локальные домены, сертификат, dump,
`self-update` и передачу команд в сервис `app`.

Домены, адрес dump
и имя БД берутся из `.env.local`.

## Composer-пакет

`bin/dev-tools` и классы `src/*` выполняются только внутри `app`-контейнера.
Они не управляют Docker и не поддерживают отдельный host-режим.

- `Cli.php` выбирает команду;
- `Config.php` хранит корень проекта;
- `Process.php` безопасно запускает процессы массивом аргументов;
- `CsFixer.php` запускает общие правила и staged-проверку;
- `PhpStan.php` выбирает `phpstan.dist.neon` и запускает анализ;
- `Hooks.php` устанавливает host hook, который возвращает проверку в Docker.

## Граница ответственности

В глобальном CLI находится только то, что нужно до `composer install` либо
управляет контейнерами. В Composer-пакете находится только PHP-код и
конфигурация инструментов качества.

Dockerfile, Compose, nginx и уникальные переменные остаются в проекте, потому
что описывают его сервисы и runtime, а не общую логику.
