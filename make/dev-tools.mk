.PHONY: cs-check cs-check-local cs-check-docker cs-fix cs-fix-local cs-fix-docker phpstan phpstan-local phpstan-docker phpstan-files hooks-local hooks-docker

DEV_TOOLS ?= vendor/bin/dev-tools

cs-check:
	$(DEV_TOOLS) cs:check

cs-check-local:
	$(DEV_TOOLS) cs:check --mode=local

cs-check-docker:
	$(DEV_TOOLS) cs:check --mode=docker

cs-fix:
	$(DEV_TOOLS) cs:fix

cs-fix-local:
	$(DEV_TOOLS) cs:fix --mode=local

cs-fix-docker:
	$(DEV_TOOLS) cs:fix --mode=docker

phpstan:
	$(DEV_TOOLS) phpstan

phpstan-local:
	$(DEV_TOOLS) phpstan --mode=local

phpstan-docker:
	$(DEV_TOOLS) phpstan --mode=docker

phpstan-files:
	@test -n "$(FILES)" || { echo "ERROR: FILES is empty"; exit 1; }
	$(DEV_TOOLS) phpstan $(FILES)

hooks-local:
	$(DEV_TOOLS) hooks:install --mode=local

hooks-docker:
	$(DEV_TOOLS) hooks:install --mode=docker
