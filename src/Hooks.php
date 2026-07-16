<?php

declare(strict_types=1);

namespace DevTools;

final readonly class Hooks
{
    private const int HOOK_PERMISSIONS = 0775;

    public function __construct(
        private Config $config,
        private Process $process,
        private string $packageDir,
    ) {
    }

    public function install(?string $mode): int
    {
        $mode ??= $this->config->mode('hooks.mode', 'local');
        if (!in_array($mode, ['local', 'docker'], true)) {
            throw new \InvalidArgumentException('Hook mode must be local or docker.');
        }

        $gitDir = $this->process->output(['git', 'rev-parse', '--git-dir'], $this->config->projectDir());
        $gitDir = str_starts_with($gitDir, '/') ? $gitDir : $this->config->path($gitDir);
        $target = $gitDir.'/hooks/pre-commit';

        if (!is_dir(dirname($target))
            && !mkdir(dirname($target), self::HOOK_PERMISSIONS, true)
            && !is_dir(dirname($target))) {
            throw new \RuntimeException('Unable to create Git hooks directory.');
        }

        $command  = $mode === 'docker' ? $this->dockerCommand() : ['vendor/bin/dev-tools', 'cs:fix-staged', '--mode=local'];
        $template = (string) file_get_contents($this->packageDir.'/hooks/pre-commit');
        $script   = str_replace('__COMMAND__', implode(' ', array_map(escapeshellarg(...), $command)), $template);

        if (file_put_contents($target, $script) === false || !chmod($target, self::HOOK_PERMISSIONS)) {
            throw new \RuntimeException('Unable to install pre-commit hook.');
        }

        echo sprintf("Git pre-commit hook installed in %s mode.\n", $mode);

        return 0;
    }

    /** @return list<string> */
    private function dockerCommand(): array
    {
        return [
            ...$this->config->dockerCommand(),
            'exec', '-T',
            '-e', 'GIT_CONFIG_COUNT=1',
            '-e', 'GIT_CONFIG_KEY_0=safe.directory',
            '-e', 'GIT_CONFIG_VALUE_0=*',
            $this->config->string('docker.service', 'app'),
            'vendor/bin/dev-tools', 'cs:fix-staged', '--mode=local',
        ];
    }
}
