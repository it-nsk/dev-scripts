# PHP CS Fixer, PHPStan и Git hooks

Пакет подключается из Packagist:

```bash
composer require --dev it-nsk/dev-tools:^0.2.0
```

В рабочем процессе Composer запускается внутри Docker через `dev-tools init`
или `dev-tools sh 'composer install'`.

## PHP CS Fixer

```bash
dev-tools cs:check
dev-tools cs:fix
```

После первого подключения `cs:fix` запускается по всему `src`. Форматирование
проверяется и сохраняется отдельным коммитом.

## PHPStan

```bash
dev-tools phpstan
dev-tools phpstan src/Service/Foo.php src/Controller/BarController.php
```

Проектный `phpstan.dist.neon` используется автоматически. Старые ошибки
фиксируются в `phpstan-baseline.neon`; новые ошибки в baseline не добавляются.

Создание baseline:

```bash
dev-tools sh \
  'vendor/bin/phpstan analyse -c phpstan.dist.neon --generate-baseline'
```

## Git hook

```bash
dev-tools hooks:install
```

Hook находится на хосте в `.git/hooks/pre-commit`, но запускает
`vendor/bin/dev-tools cs:fix-staged` внутри `app`-контейнера. PHP на хосте
не требуется.

Перед PR:

```bash
dev-tools cs:check
dev-tools phpstan
```
