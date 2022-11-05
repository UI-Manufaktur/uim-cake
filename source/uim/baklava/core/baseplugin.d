

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 */module uim.baklava.core;

import uim.baklava.console.commandCollection;
import uim.baklava.https\MiddlewareQueue;
import uim.baklava.Routing\RouteBuilder;
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
    protected myPath;

    /**
     * The class path for this plugin.
     *
     * @var string
     */
    protected myClassPath;

    /**
     * The config path for this plugin.
     *
     * @var string
     */
    protected myConfigPath;

    /**
     * The templates path for this plugin.
     *
     * @var string
     */
    protected myTemplatePath;

    /**
     * The name of this plugin
     *
     * @var string
     */
    protected string myName;

    /**
     * Constructor
     *
     * @param array<string, mixed> myOptions Options
     */
    this(array myOptions = []) {
        foreach (static::VALID_HOOKS as myKey) {
            if (isset(myOptions[myKey])) {
                this.{"{myKey}Enabled"} = (bool)myOptions[myKey];
            }
        }
        foreach (['name', 'path', 'classPath', 'configPath', 'templatePath'] as myPath) {
            if (isset(myOptions[myPath])) {
                this.{myPath} = myOptions[myPath];
            }
        }

        this.initialize();
    }

    /**
     * Initialization hook called from constructor.
     *
     * @return void
     */
    function initialize(): void
    {
    }


    string getName() {
        if (this.name) {
            return this.name;
        }
        $parts = explode('\\', static::class);
        array_pop($parts);
        this.name = implode('/', $parts);

        return this.name;
    }


    string getPath() {
        if (this.path) {
            return this.path;
        }
        $reflection = new ReflectionClass(this);
        myPath = dirname($reflection.getFileName());

        // Trim off src
        if (substr(myPath, -3) === 'src') {
            myPath = substr(myPath, 0, -3);
        }
        this.path = rtrim(myPath, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;

        return this.path;
    }


    string getConfigPath() {
        if (this.configPath) {
            return this.configPath;
        }
        myPath = this.getPath();

        return myPath . 'config' . DIRECTORY_SEPARATOR;
    }


    string getClassPath() {
        if (this.classPath) {
            return this.classPath;
        }
        myPath = this.getPath();

        return myPath . 'src' . DIRECTORY_SEPARATOR;
    }


    string getTemplatePath() {
        if (this.templatePath) {
            return this.templatePath;
        }
        myPath = this.getPath();

        return this.templatePath = myPath . 'templates' . DIRECTORY_SEPARATOR;
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


    bool isEnabled(string $hook) {
        this.checkHook($hook);

        return this.{"{$hook}Enabled"} === true;
    }

    /**
     * Check if a hook name is valid
     *
     * @param string $hook The hook name to check
     * @throws \InvalidArgumentException on invalid hooks
     * @return void
     */
    protected auto checkHook(string $hook): void
    {
        if (!in_array($hook, static::VALID_HOOKS, true)) {
            throw new InvalidArgumentException(
                "`$hook` is not a valid hook name. Must be one of " . implode(', ', static::VALID_HOOKS)
            );
        }
    }


    function routes(RouteBuilder $routes): void
    {
        myPath = this.getConfigPath() . 'routes.php';
        if (is_file(myPath)) {
            $return = require myPath;
            if ($return instanceof Closure) {
                $return($routes);
            }
        }
    }


    function bootstrap(PluginApplicationInterface $app): void
    {
        $bootstrap = this.getConfigPath() . 'bootstrap.php';
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
     * @param \Cake\Core\IContainer myContainer The container to add services to.
     * @return void
     */
    function services(IContainer myContainer): void
    {
    }
}