<?php

declare(strict_types=1);

namespace DevTools;

use Symfony\Component\Yaml\Exception\ParseException;
use Symfony\Component\Yaml\Yaml;

final class Config
{
    /** @param array<string, mixed> $values */
    private function __construct(
        private readonly string $projectDir,
        private readonly string $file,
        private readonly array $values,
    ) {
    }

    public static function load(string $projectDir, ?string $file = null): self
    {
        $projectDir = rtrim($projectDir, '/');
        $file ??= $projectDir.'/.dev-tools.yaml';

        if (!is_file($file)) {
            return new self($projectDir, $file, []);
        }

        try {
            $values = Yaml::parseFile($file);
        } catch (ParseException $exception) {
            throw new \InvalidArgumentException(sprintf('Invalid YAML in %s: %s', $file, $exception->getMessage()), 0, $exception);
        }

        if ($values !== null && !is_array($values)) {
            throw new \InvalidArgumentException(sprintf('The root value in %s must be a mapping.', $file));
        }

        return new self($projectDir, $file, $values ?? []);
    }

    public function projectDir(): string
    {
        return $this->projectDir;
    }

    public function file(): string
    {
        return $this->file;
    }

    public function string(string $path, string $default): string
    {
        $value = $this->value($path, $default);

        if (!is_string($value) || $value === '') {
            throw new \InvalidArgumentException(sprintf('Configuration value "%s" must be a non-empty string.', $path));
        }

        return $value;
    }

    public function nullableString(string $path): ?string
    {
        $value = $this->value($path);

        if ($value === null) {
            return null;
        }

        if (!is_string($value) || $value === '') {
            throw new \InvalidArgumentException(sprintf('Configuration value "%s" must be a non-empty string or null.', $path));
        }

        return $value;
    }

    /** @return list<string> */
    public function strings(string $path, array $default = []): array
    {
        $value = $this->value($path, $default);

        if (!is_array($value) || !array_is_list($value)) {
            throw new \InvalidArgumentException(sprintf('Configuration value "%s" must be a list.', $path));
        }

        foreach ($value as $item) {
            if (!is_string($item) || $item === '') {
                throw new \InvalidArgumentException(sprintf('Every item in "%s" must be a non-empty string.', $path));
            }
        }

        return $value;
    }

    public function mode(string $path, string $default): string
    {
        $mode = $this->string($path, $default);

        if (!in_array($mode, ['local', 'docker'], true)) {
            throw new \InvalidArgumentException(sprintf('Configuration value "%s" must be local or docker.', $path));
        }

        return $mode;
    }

    public function path(string $path): string
    {
        return $this->projectDir.'/'.ltrim($path, '/');
    }

    /** @return list<string> */
    public function dockerPrefix(): array
    {
        return [...$this->dockerCommand(), 'exec', '-T', $this->string('docker.service', 'app')];
    }

    /** @return list<string> */
    public function dockerCommand(): array
    {
        $command = $this->strings('docker.command', ['docker', 'compose']);

        foreach ($this->strings('docker.env_files', ['.env', '.env.local']) as $envFile) {
            if (is_file($this->path($envFile))) {
                $command[] = '--env-file';
                $command[] = $envFile;
            }
        }

        return $command;
    }

    private function value(string $path, mixed $default = null): mixed
    {
        $value = $this->values;

        foreach (explode('.', $path) as $part) {
            if (!is_array($value) || !array_key_exists($part, $value)) {
                return $default;
            }

            $value = $value[$part];
        }

        return $value;
    }
}
