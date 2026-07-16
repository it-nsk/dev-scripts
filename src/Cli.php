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
            $configFile = $this->takeOption($options, '--config');
            $mode       = $this->takeOption($options, '--mode');
            $config     = Config::load($this->findProjectDir(getcwd() ?: '.'), $configFile);
            $process    = new Process();

            return match ($command) {
                'cs:check'      => (new CsFixer($config, $process))->check($mode),
                'cs:fix'        => (new CsFixer($config, $process))->fix($mode),
                'cs:fix-staged' => (new CsFixer($config, $process))->fixStaged($mode),
                'phpstan'       => (new PhpStan($config, $process))->analyse($options, $mode),
                'hooks:install' => (new Hooks($config, $process, $this->packageDir))->install($mode),
                default         => throw new \InvalidArgumentException(sprintf('Unknown command: %s', $command)),
            };
        } catch (\Throwable $exception) {
            fwrite(STDERR, 'ERROR: '.$exception->getMessage()."\n");

            return 1;
        }
    }

    /** @param list<string> $arguments */
    private function takeOption(array &$arguments, string $name): ?string
    {
        foreach ($arguments as $index => $argument) {
            if ($argument === $name) {
                $value = $arguments[$index + 1] ?? null;
                if ($value === null || str_starts_with($value, '--')) {
                    throw new \InvalidArgumentException(sprintf('%s requires a value.', $name));
                }
                array_splice($arguments, $index, 2);

                return $value;
            }

            if (str_starts_with($argument, $name.'=')) {
                array_splice($arguments, $index, 1);

                return substr($argument, strlen($name) + 1);
            }
        }

        return null;
    }

    private function findProjectDir(string $directory): string
    {
        $directory = realpath($directory) ?: $directory;

        while (!is_file($directory.'/.dev-tools.yaml') && !is_dir($directory.'/.git')) {
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
  dev-tools cs:check [--mode=local|docker]
  dev-tools cs:fix [--mode=local|docker]
  dev-tools cs:fix-staged [--mode=local|docker]
  dev-tools phpstan [path...] [--mode=local|docker]
  dev-tools hooks:install [--mode=local|docker]

All commands accept --config=path/to/config.yaml.

TXT;

        return 0;
    }
}
