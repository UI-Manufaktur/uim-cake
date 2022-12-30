

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.6.0
  */
module uim.cake.Core;

import uim.cake.consoles.CommandCollection;
import uim.cake.http.MiddlewareQueue;
import uim.cake.routings.RouteBuilder;
use Closure;
use InvalidArgumentException;
use ReflectionClass;

/**
 * Base Plugin Class
 *
 * Every plugin should extend from this class or implement the interfaces and
 * include a plugin class in its src root folder.
 */
class BasePlugin : PluginInterface
{
    /**
     * Do bootstrapping or not
     *
     */
    protected bool $bootstrapEnabled = true;

    /**
     * Console middleware
     *
     */
    protected bool $consoleEnabled = true;

    /**
     * Enable middleware
     *
     */
    protected bool $middlewareEnabled = true;

    /**
     * Register container services
     *
     */
    protected bool $servicesEnabled = true;

    /**
     * Load routes or not
     *
     */
    protected bool $routesEnabled = true;

    /**
     * The path to this plugin.
     *
     */
    protected string $path;

    /**
     * The class path for this plugin.
     *
     */
    protected string $classPath;

    /**
     * The config path for this plugin.
     *
     */
    protected string $configPath;

    /**
     * The templates path for this plugin.
     *
     */
    protected string $templatePath;

    /**
     * The name of this plugin
     *
     */
    protected string $name;

    /**
     * Constructor
     *
     * @param array<string, mixed> $options Options
     */
    this(array $options = []) {
        foreach (static::VALID_HOOKS as $key) {
            if (isset($options[$key])) {
                this.{"{$key}Enabled"} = (bool)$options[$key];
            }
        }
        foreach (["name", "path", "classPath", "configPath", "templatePath"] as $path) {
            if (isset($options[$path])) {
                this.{$path} = $options[$path];
            }
        }

        this.initialize();
    }

    /**
     * Initialization hook called from constructor.
     */
    void initialize() {
    }


    function getName(): string
    {
        if (this.name) {
            return this.name;
        }
        $parts = explode("\\", static::class);
        array_pop($parts);
        this.name = implode("/", $parts);

        return this.name;
    }


    function getPath(): string
    {
        if (this.path) {
            return this.path;
        }
        $reflection = new ReflectionClass(this);
        $path = dirname($reflection.getFileName());

        // Trim off src
        if (substr($path, -3) == "src") {
            $path = substr($path, 0, -3);
        }
        this.path = rtrim($path, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;

        return this.path;
    }


    function getConfigPath(): string
    {
        if (this.configPath) {
            return this.configPath;
        }
        $path = this.getPath();

        return $path . "config" . DIRECTORY_SEPARATOR;
    }


    function getClassPath(): string
    {
        if (this.classPath) {
            return this.classPath;
        }
        $path = this.getPath();

        return $path . "src" . DIRECTORY_SEPARATOR;
    }


    function getTemplatePath(): string
    {
        if (this.templatePath) {
            return this.templatePath;
        }
        $path = this.getPath();

        return this.templatePath = $path . "templates" . DIRECTORY_SEPARATOR;
    }


    function enable(string $hook) {
        this.checkHook($hook);
        this.{"{$hook}Enabled}"} = true;

        return this;
    }


    function disable(string $hook) {
        this.checkHook($hook);
        this.{"{$hook}Enabled"} = false;

        return this;
    }


    function isEnabled(string $hook): bool
    {
        this.checkHook($hook);

        return this.{"{$hook}Enabled"} == true;
    }

    /**
     * Check if a hook name is valid
     *
     * @param string $hook The hook name to check
     * @throws \InvalidArgumentException on invalid hooks
     */
    protected void checkHook(string $hook) {
        if (!in_array($hook, static::VALID_HOOKS, true)) {
            throw new InvalidArgumentException(
                "`$hook` is not a valid hook name. Must be one of " . implode(", ", static::VALID_HOOKS)
            );
        }
    }

    void routes(RouteBuilder $routes) {
        $path = this.getConfigPath() . "routes.php";
        if (is_file($path)) {
            $return = require $path;
            if ($return instanceof Closure) {
                $return($routes);
            }
        }
    }


    void bootstrap(IPluginApplication $app) {
        $bootstrap = this.getConfigPath() . "bootstrap.php";
        if (is_file($bootstrap)) {
            require $bootstrap;
        }
    }


    function console(CommandCollection $commands): CommandCollection
    {
        return $commands.addMany($commands.discoverPlugin(this.getName()));
    }


    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue
    {
        return $middlewareQueue;
    }

    /**
     * Register container services for this plugin.
     *
     * @param uim.cake.Core\IContainer $container The container to add services to.
     */
    void services(IContainer $container) {
    }
}
