<?php

declare(strict_types=1);

namespace DevTools;

final readonly class Config
{
    private function __construct(private string $projectDir)
    {
    }

    public static function load(string $projectDir): self
    {
        return new self(rtrim($projectDir, '/'));
    }

    public function projectDir(): string
    {
        return $this->projectDir;
    }

    public function path(string $path): string
    {
        return $this->projectDir.'/'.ltrim($path, '/');
    }
}
