<?php

declare(strict_types=1);

namespace DevTools;

final readonly class CsFixer
{
    public function __construct(private Config $config, private Process $process)
    {
    }

    public function check(): int
    {
        return $this->run([...$this->command(), '--verbose', '--dry-run', '--diff']);
    }

    public function fix(): int
    {
        return $this->run([...$this->command(), '--verbose']);
    }

    public function fixStaged(): int
    {
        $files = preg_split('/\R/', $this->process->output([
            'git', 'diff', '--cached', '--name-only', '--diff-filter=ACM', '--', '*.php',
        ], $this->config->projectDir())) ?: [];
        $files = array_values(array_filter($files));

        if ($files === []) {
            return 0;
        }

        $exitCode = $this->run([...$this->command(), '--path-mode=intersection', ...$files]);
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
            'vendor/bin/php-cs-fixer',
            'fix',
            '--config=vendor/it-nsk/dev-tools/config/php-cs-fixer.php',
        ];
    }

    /** @param list<string> $command */
    private function run(array $command): int
    {
        return $this->process->run($command, $this->config->projectDir(), [
            'DEV_TOOLS_PROJECT_DIR' => $this->config->projectDir(),
        ]);
    }
}
