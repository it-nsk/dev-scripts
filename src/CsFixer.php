<?php

declare(strict_types=1);

namespace DevTools;

final readonly class CsFixer
{
    public function __construct(private Config $config, private Process $process)
    {
    }

    public function check(?string $mode = null): int
    {
        return $this->run([...$this->command(), '--verbose', '--dry-run', '--diff'], $this->resolveMode($mode));
    }

    public function fix(?string $mode = null): int
    {
        return $this->run([...$this->command(), '--verbose'], $this->resolveMode($mode));
    }

    public function fixStaged(?string $mode): int
    {
        $files = preg_split('/\R/', $this->process->output([
            'git', 'diff', '--cached', '--name-only', '--diff-filter=ACM', '--', '*.php',
        ], $this->config->projectDir())) ?: [];
        $files = array_values(array_filter($files));

        if ($files === []) {
            return 0;
        }

        $mode ??= $this->config->mode('hooks.mode', $this->config->mode('cs_fixer.mode', 'local'));
        $mode     = $this->resolveMode($mode);
        $exitCode = $this->run([...$this->command(), '--path-mode=intersection', ...$files], $mode);
        if ($exitCode !== 0) {
            return $exitCode;
        }

        foreach ($files as $file) {
            if (is_file($this->config->path($file))) {
                $exitCode = $this->process->run(['git', 'add', '--', $file], $this->config->projectDir());
                if ($exitCode !== 0) {
                    return $exitCode;
                }
            }
        }

        return 0;
    }

    /** @return list<string> */
    private function command(): array
    {
        return [
            $this->config->string('cs_fixer.binary', 'vendor/bin/php-cs-fixer'),
            'fix',
            '--config='.$this->config->string('cs_fixer.config', 'vendor/dev-tools/dev-tools/config/php-cs-fixer.php'),
        ];
    }

    /** @param list<string> $command */
    private function run(array $command, string $mode): int
    {
        if ($mode === 'docker') {
            $command = [...$this->config->dockerPrefix(), ...$command];
        }

        return $this->process->run($command, $this->config->projectDir(), [
            'DEV_TOOLS_CONFIG'      => $this->config->file(),
            'DEV_TOOLS_PROJECT_DIR' => $this->config->projectDir(),
        ]);
    }

    private function resolveMode(?string $mode): string
    {
        if ($mode === null) {
            return $this->config->mode('cs_fixer.mode', 'local');
        }
        if (!in_array($mode, ['local', 'docker'], true)) {
            throw new \InvalidArgumentException('CS Fixer mode must be local or docker.');
        }

        return $mode;
    }
}
