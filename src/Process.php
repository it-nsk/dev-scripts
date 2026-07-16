<?php

declare(strict_types=1);

namespace DevTools;

final class Process
{
    /** @param list<string> $command @param array<string, string> $environment */
    public function run(array $command, string $cwd, array $environment = []): int
    {
        $process = proc_open(
            $command,
            [0 => STDIN, 1 => STDOUT, 2 => STDERR],
            $pipes,
            $cwd,
            $environment === [] ? null : array_replace(getenv(), $environment),
        );

        if (!is_resource($process)) {
            throw new \RuntimeException(sprintf('Unable to start command: %s', implode(' ', $command)));
        }

        return proc_close($process);
    }

    /** @param list<string> $command */
    public function output(array $command, string $cwd): string
    {
        $process = proc_open($command, [1 => ['pipe', 'w'], 2 => STDERR], $pipes, $cwd);

        if (!is_resource($process)) {
            throw new \RuntimeException(sprintf('Unable to start command: %s', implode(' ', $command)));
        }

        $output = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $exitCode = proc_close($process);

        if ($exitCode !== 0) {
            throw new \RuntimeException(sprintf('Command failed: %s', implode(' ', $command)));
        }

        return trim($output);
    }
}
