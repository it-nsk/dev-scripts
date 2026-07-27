<?php

declare(strict_types=1);

namespace DevTools;

final readonly class PhpStan
{
    public function __construct(private Config $config, private Process $process)
    {
    }

    /** @param list<string> $paths */
    public function analyse(array $paths): int
    {
        $defaultProjectConfig = $this->config->path('phpstan.dist.neon');
        $hasProjectConfig     = is_file($defaultProjectConfig);
        $configuration        = $hasProjectConfig
            ? 'phpstan.dist.neon'
            : 'vendor/it-nsk/dev-tools/config/phpstan.neon';
        if ($paths === [] && !$hasProjectConfig) {
            $paths = ['src'];
        }
        $command = [
            'vendor/bin/phpstan',
            'analyse',
            '--configuration='.$configuration,
            '--memory-limit=1G',
            '--no-progress',
            ...$paths,
        ];

        return $this->process->run($command, $this->config->projectDir());
    }
}
