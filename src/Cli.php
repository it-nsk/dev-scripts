<?php

declare(strict_types=1);

namespace DevTools;

final class Cli
{
    public function __construct(private readonly string $packageDir)
    {
    }

    /** @param list<string> $arguments */
    public function run(array $arguments): int
    {
        $command = $arguments[1] ?? 'help';
        $options = array_slice($arguments, 2);

        if (in_array($command, ['list', 'help', '--help', '-h'], true)) {
            return $this->help();
        }

        try {
            $config  = Config::load($this->findProjectDir(getcwd() ?: '.'));
            $process = new Process();

            return match ($command) {
                'cs:check'      => (new CsFixer($config, $process))->check(),
                'cs:fix'        => (new CsFixer($config, $process))->fix(),
                'cs:fix-staged' => (new CsFixer($config, $process))->fixStaged(),
                'phpstan'       => (new PhpStan($config, $process))->analyse($options),
                'hooks:install' => (new Hooks($config, $process, $this->packageDir))->install(),
                default         => throw new \InvalidArgumentException(sprintf('Unknown command: %s', $command)),
            };
        } catch (\Throwable $exception) {
            fwrite(STDERR, 'ERROR: '.$exception->getMessage()."\n");

            return 1;
        }
    }

    private function findProjectDir(string $directory): string
    {
        $directory = realpath($directory) ?: $directory;

        while (!is_dir($directory.'/.git')) {
            $parent = dirname($directory);
            if ($parent === $directory) {
                throw new \RuntimeException('Run dev-tools inside a project directory.');
            }
            $directory = $parent;
        }

        return $directory;
    }

    private function help(): int
    {
        echo <<<'TXT'
Dev Tools

Commands:
  dev-tools cs:check
  dev-tools cs:fix
  dev-tools cs:fix-staged
  dev-tools phpstan [path...]
  dev-tools hooks:install

TXT;

        return 0;
    }
}
