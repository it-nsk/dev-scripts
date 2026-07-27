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

    public function install(): int
    {
        $gitDir = $this->process->output(['git', 'rev-parse', '--git-dir'], $this->config->projectDir());
        $gitDir = str_starts_with($gitDir, '/') ? $gitDir : $this->config->path($gitDir);
        $target = $gitDir.'/hooks/pre-commit';

        if (!is_dir(dirname($target))
            && !mkdir(dirname($target), self::HOOK_PERMISSIONS, true)
            && !is_dir(dirname($target))) {
            throw new \RuntimeException('Unable to create Git hooks directory.');
        }

        $command  = $this->dockerCommand();
        $template = (string) file_get_contents($this->packageDir.'/hooks/pre-commit');
        $script   = str_replace('__COMMAND__', implode(' ', array_map(escapeshellarg(...), $command)), $template);

        if ((is_file($target) || is_link($target)) && !unlink($target)) {
            throw new \RuntimeException('Unable to replace existing Git pre-commit hook.');
        }

        if (file_put_contents($target, $script) === false || !chmod($target, self::HOOK_PERMISSIONS)) {
            throw new \RuntimeException('Unable to install pre-commit hook.');
        }

        echo "Git pre-commit hook installed.\n";

        return 0;
    }

    /** @return list<string> */
    private function dockerCommand(): array
    {
        $command = ['docker', 'compose', '--env-file', '.env'];
        if (is_file($this->config->path('.env.local'))) {
            $command = [...$command, '--env-file', '.env.local'];
        }

        return [
            ...$command, 'exec', '-T',
            '-e', 'GIT_CONFIG_COUNT=1',
            '-e', 'GIT_CONFIG_KEY_0=safe.directory',
            '-e', 'GIT_CONFIG_VALUE_0=*',
            'app', 'vendor/bin/dev-tools', 'cs:fix-staged',
        ];
    }
}
