<?php

declare(strict_types=1);

use DevTools\Config;
use PhpCsFixer\Config as PhpCsFixerConfig;
use PhpCsFixer\Finder;

$projectDir = getenv('DEV_TOOLS_PROJECT_DIR') ?: getcwd();
$configFile = getenv('DEV_TOOLS_CONFIG') ?: $projectDir.'/.dev-tools.yaml';
$config     = Config::load($projectDir, $configFile);
$finder     = Finder::create()
    ->in(array_map($config->path(...), $config->strings('cs_fixer.paths', ['src'])))
    ->exclude($config->strings('cs_fixer.exclude'));

return (new PhpCsFixerConfig())
    ->setRules([
        '@Symfony'                                         => true,
        'array_syntax'                                     => false,
        'binary_operator_spaces'                           => [
            'operators' => [
                '='  => 'align_single_space_minimal',
                '=>' => 'align_single_space_minimal_by_scope',
            ],
        ],
        'increment_style'                                  => false,
        'lambda_not_used_import'                           => false,
        'no_useless_else'                                  => false,
        'no_useless_return'                                => false,
        'nullable_type_declaration_for_default_null_value' => false,
        'protected_to_private'                             => false,
        'standardize_increment'                            => false,
        'yoda_style'                                       => false,
    ])
    ->setRiskyAllowed(false)
    ->setFinder($finder);
