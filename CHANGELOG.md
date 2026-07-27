# Changelog

Все заметные изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версии следуют [Semantic Versioning](https://semver.org/lang/ru/).

## Unreleased

### Added

- общие команды PHP CS Fixer и PHPStan;
- глобальный `dev-tools` для Docker lifecycle и проектных команд;
- одноразовый установщик и команда `self-update`;
- скачивание и импорт MySQL gzip dump;
- E2E установки, обновления и импорта dump в чистый MySQL-контейнер.

### Changed

- все пользовательские команды выполняются через глобальный Docker CLI;
- Composer-пакет выполняет PHP-инструменты только внутри `app`-контейнера;
- `dev-tools sh` заменяет отдельные Composer, npm и Symfony-обертки;
- типовые настройки перенесены в defaults, `.dev-tools.yaml` больше не нужен;
- глобальный CLI обновлен до версии `0.3.0`.

### Removed

- local/Docker modes внутреннего Composer-бинарника;
- Makefile-интеграция и YAML-конфигурация проекта.
