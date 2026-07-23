<?php

declare(strict_types=1);

namespace DevTools;

final readonly class PhpStan
{
    public function __construct(private Config $config, private Process $process)
    {
    }

    /** @param list<string> $paths */
    public function analyse(array $paths, ?string $mode = null): int
    {
        $paths         = $paths !== [] ? $paths : $this->config->strings('phpstan.paths', ['src']);
        $projectConfig = $this->config->nullableString('phpstan.config');
        $configuration = $projectConfig ?? $this->config->string(
            'phpstan.default_config',
            'vendor/it-nsk/dev-tools/config/phpstan.neon',
        );
        $command = [
            $this->config->string('phpstan.binary', 'vendor/bin/phpstan'),
            'analyse',
            '--configuration='.$configuration,
            '--memory-limit='.$this->config->string('phpstan.memory_limit', '1G'),
            '--no-progress',
            ...$paths,
        ];

        $mode ??= $this->config->mode('phpstan.mode', 'local');
        if (!in_array($mode, ['local', 'docker'], true)) {
            throw new \InvalidArgumentException('PHPStan mode must be local or docker.');
        }
        if ($mode === 'docker') {
            $command = [...$this->config->dockerPrefix(), ...$command];
        }

        return $this->process->run($command, $this->config->projectDir());
    }
}
