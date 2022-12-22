<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Core;

use Cake\Console\CommandCollection;
use Cake\Http\MiddlewareQueue;
use Cake\Routing\RouteBuilder;
use Closure;
use InvalidArgumentException;
use ReflectionClass;

/**
 * Base Plugin Class
 *
 * Every plugin should extend from this class or implement the interfaces and
 * include a plugin class in its src root folder.
 */
class BasePlugin implements PluginInterface
{
    /**
     * Do bootstrapping or not
     *
     * @var bool
     */
    protected $bootstrapEnabled = true;

    /**
     * Console middleware
     *
     * @var bool
     */
    protected $consoleEnabled = true;

    /**
     * Enable middleware
     *
     * @var bool
     */
    protected $middlewareEnabled = true;

    /**
     * Register container services
     *
     * @var bool
     */
    protected $servicesEnabled = true;

    /**
     * Load routes or not
     *
     * @var bool
     */
    protected $routesEnabled = true;

    /**
     * The path to this plugin.
     *
     * @var string
     */
    protected $path;

    /**
     * The class path for this plugin.
     *
     * @var string
     */
    protected $classPath;

    /**
     * The config path for this plugin.
     *
     * @var string
     */
    protected $configPath;

    /**
     * The templates path for this plugin.
     *
     * @var string
     */
    protected $templatePath;

    /**
     * The name of this plugin
     *
     * @var string
     */
    protected $name;

    /**
     * Constructor
     *
     * @param array<string, mixed> $options Options
     */
    public this(array $options = [])
    {
        foreach (static::VALID_HOOKS as $key) {
            if (isset($options[$key])) {
                this->{"{$key}Enabled"} = (bool)$options[$key];
            }
        }
        foreach (['name', 'path', 'classPath', 'configPath', 'templatePath'] as $path) {
            if (isset($options[$path])) {
                this->{$path} = $options[$path];
            }
        }

        this->initialize();
    }

    /**
     * Initialization hook called from constructor.
     *
     * @return void
     */
    function initialize(): void
    {
    }

    /**
     * @inheritDoc
     */
    function getName(): string
    {
        if (this->name) {
            return this->name;
        }
        $parts = explode('\\', static::class);
        array_pop($parts);
        this->name = implode('/', $parts);

        return this->name;
    }

    /**
     * @inheritDoc
     */
    function getPath(): string
    {
        if (this->path) {
            return this->path;
        }
        $reflection = new ReflectionClass(this);
        $path = dirname($reflection->getFileName());

        // Trim off src
        if (substr($path, -3) == 'src') {
            $path = substr($path, 0, -3);
        }
        this->path = rtrim($path, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;

        return this->path;
    }

    /**
     * @inheritDoc
     */
    function getConfigPath(): string
    {
        if (this->configPath) {
            return this->configPath;
        }
        $path = this->getPath();

        return $path . 'config' . DIRECTORY_SEPARATOR;
    }

    /**
     * @inheritDoc
     */
    function getClassPath(): string
    {
        if (this->classPath) {
            return this->classPath;
        }
        $path = this->getPath();

        return $path . 'src' . DIRECTORY_SEPARATOR;
    }

    /**
     * @inheritDoc
     */
    function getTemplatePath(): string
    {
        if (this->templatePath) {
            return this->templatePath;
        }
        $path = this->getPath();

        return this->templatePath = $path . 'templates' . DIRECTORY_SEPARATOR;
    }

    /**
     * @inheritDoc
     */
    function enable(string $hook)
    {
        this->checkHook($hook);
        this->{"{$hook}Enabled}"} = true;

        return this;
    }

    /**
     * @inheritDoc
     */
    function disable(string $hook)
    {
        this->checkHook($hook);
        this->{"{$hook}Enabled"} = false;

        return this;
    }

    /**
     * @inheritDoc
     */
    function isEnabled(string $hook): bool
    {
        this->checkHook($hook);

        return this->{"{$hook}Enabled"} == true;
    }

    /**
     * Check if a hook name is valid
     *
     * @param string $hook The hook name to check
     * @throws \InvalidArgumentException on invalid hooks
     * @return void
     */
    protected function checkHook(string $hook): void
    {
        if (!in_array($hook, static::VALID_HOOKS, true)) {
            throw new InvalidArgumentException(
                "`$hook` is not a valid hook name. Must be one of " . implode(', ', static::VALID_HOOKS)
            );
        }
    }

    /**
     * @inheritDoc
     */
    function routes(RouteBuilder $routes): void
    {
        $path = this->getConfigPath() . 'routes.php';
        if (is_file($path)) {
            $return = require $path;
            if ($return instanceof Closure) {
                $return($routes);
            }
        }
    }

    /**
     * @inheritDoc
     */
    function bootstrap(PluginApplicationInterface $app): void
    {
        $bootstrap = this->getConfigPath() . 'bootstrap.php';
        if (is_file($bootstrap)) {
            require $bootstrap;
        }
    }

    /**
     * @inheritDoc
     */
    function console(CommandCollection $commands): CommandCollection
    {
        return $commands->addMany($commands->discoverPlugin(this->getName()));
    }

    /**
     * @inheritDoc
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue
    {
        return $middlewareQueue;
    }

    /**
     * Register container services for this plugin.
     *
     * @param \Cake\Core\IContainer $container The container to add services to.
     * @return void
     */
    function services(IContainer $container): void
    {
    }
}
