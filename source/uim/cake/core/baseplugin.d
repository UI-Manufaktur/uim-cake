/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.core;

import uim.cake.console.commandCollection;
import uim.caketps\MiddlewareQueue;
import uim.cake.routings\RouteBuilder;
use Closure;
use InvalidArgumentException;
use ReflectionClass;

/**
 * Base Plugin Class
 *
 * Every plugin should extend from this class or implement the interfaces and
 * include a plugin class in its src root folder.
 */
class BasePlugin : IPlugin
{
    /**
     * Do bootstrapping or not
     *
     * @var bool
     */
    protected $bootstrapEnabled = true;

    // Console middleware
    protected bool consoleEnabled = true;

    // Enable middleware
    protected bool middlewareEnabled = true;

    // Register container services
    protected bool servicesEnabled = true;

    // Load routes or not
    protected bool routesEnabled = true;

    // The path to this plugin.
    protected string myPath;

    // The class path for this plugin.
    protected string myClassPath;

    // The config path for this plugin.
    protected string myConfigPath;

    // The templates path for this plugin.
    protected string myTemplatePath;

    // The name of this plugin
    protected string string myName;

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
        foreach (["name", "path", "classPath", "configPath", "templatePath"] as myPath) {
            if (isset(myOptions[myPath])) {
                this.{myPath} = myOptions[myPath];
            }
        }

        this.initialize();
    }

    // Initialization hook called from constructor.
    void initialize() {
    }

    @property string Name() {
        if (_name) return _name;

        $parts = explode("\\", static::class);
        array_pop($parts);
        this.name = implode("/", $parts);

        return this.name;
    }


    @property string Path() {
        if (_path) return _path;

        $reflection = new ReflectionClass(this);
        myPath = dirname($reflection.getFileName());

        // Trim off src
        if (substr(myPath, -3) == "src") {
            myPath = substr(myPath, 0, -3);
        }
        this.path = rtrim(myPath, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;

        return this.path;
    }


    @property string ConfigPath() {
        if (_configPath) return configPath;

        auto myPath = this.path();

        return myPath . "config" . DIRECTORY_SEPARATOR;
    }


    @property string classPath() {
        if (_classPath) return _classPath;

        auto myPath = this.path();

        return myPath . "src" . DIRECTORY_SEPARATOR;
    }


    @property string TemplatePath() {
        if (_templatePath) return _templatePath;
        
        auto myPath = this.path();

        return this.templatePath = myPath . "templates" . DIRECTORY_SEPARATOR;
    }


    function enable(string hook) {
        this.checkHook($hook);
        this.{"{$hook}Enabled}"} = true;

        return this;
    }


    function disable(string hook) {
        this.checkHook($hook);
        this.{"{$hook}Enabled"} = false;

        return this;
    }


    bool isEnabled(string hook) {
        this.checkHook($hook);

        return this.{"{$hook}Enabled"} == true;
    }

    /**
     * Check if a hook name is valid
     *
     * @param string hook The hook name to check
     * @throws \InvalidArgumentException on invalid hooks
     */
    protected void checkHook(string hook) {
        if (!in_array($hook, static::VALID_HOOKS, true)) {
            throw new InvalidArgumentException(
                "`$hook` is not a valid hook name. Must be one of " . implode(", ", static::VALID_HOOKS)
            );
        }
    }


    void routes(RouteBuilder $routes) {
        myPath = this.getConfigPath() . "routes.php";
        if (is_file(myPath)) {
            $return = require myPath;
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


    CommandCollection console(CommandCollection $commands) {
        return $commands.addMany($commands.discoverPlugin(this.getName()));
    }


    MiddlewareQueue middleware(MiddlewareQueue $middlewareQueue) {
        return $middlewareQueue;
    }

    /**
     * Register container services for this plugin.
     *
     * @param \Cake\Core\IContainer myContainer The container to add services to.
     */
    void services(IContainer myContainer) {
    }
}
