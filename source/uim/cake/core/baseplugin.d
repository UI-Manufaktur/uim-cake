/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.baseplugin;

@safe:
import uim.cake;

/**
 * Base Plugin Class
 *
 * Every plugin should extend from this class or implement the interfaces and
 * include a plugin class in its src root folder.
 */
class BasePlugin : IPlugin {
    // Do bootstrapping or not
    protected bool $bootstrapEnabled = true;

    // Console middleware
    protected bool $consoleEnabled = true;

    // Enable middleware
    protected bool $middlewareEnabled = true;

    // Register container services
    protected bool $servicesEnabled = true;

    // Load routes or not
    protected bool $routesEnabled = true;

    // The path to this plugin.
    protected string $path;

    // The class path for this plugin.
    protected string $classPath;

    // The config path for this plugin.
    protected string _configPath;

    // The templates path for this plugin.
    protected string $templatePath;

    // The name of this plugin
    protected string _name;

    /**
     * Constructor
     * @param array<string, mixed> $options Options
     */
    this(STRINGAA someOptions = []) {
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

    // Initialization hook called from constructor.
    void initialize() {
    }

    @propery string Name() {
      if (_name) { // Name exists
        return _name;
      }

      // Generate new name
      $parts = explode("\\", static::class);
      array_pop($parts);
      _name = implode("/", $parts);

      return _name;
    }

    string getPath() {
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


    string getConfigPath() {
        if (_configPath) {
            return _configPath;
        }
        auto myPath = this.getPath();

        return myPath ~ "config" ~ DIRECTORY_SEPARATOR;
    }


    string getClassPath() {
        if (_classPath) {
            return _classPath;
        }
        auto myPath = this.getPath();

        return myPath ~ "src" ~ DIRECTORY_SEPARATOR;
    }


    string getTemplatePath() {
        if (_templatePath) {
            return _templatePath;
        }
        auto myPath = this.getPath();

        _templatePath = myPath ~ "templates" ~ DIRECTORY_SEPARATOR;
        return _templatePath;
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

        return this.{"{$hook}Enabled"} == true;
    }

    /**
     * Check if a hook name is valid
     *
     * @param string $hook The hook name to check
     * @throws \InvalidArgumentException on invalid hooks
     */
    protected void checkHook(string $hook) {
        if (!hasAllValues($hook, static::VALID_HOOKS, true)) {
            throw new InvalidArgumentException(
                "`$hook` is not a valid hook name. Must be one of " ~ implode(", ", static::VALID_HOOKS)
            );
        }
    }

    void routes(RouteBuilder $routes) {
        $path = this.getConfigPath() ~ "routes.php";
        if (is_file($path)) {
            $return = require $path;
            if ($return instanceof Closure) {
                $return($routes);
            }
        }
    }


    void bootstrap(IPluginApplication $app) {
        $bootstrap = this.getConfigPath() ~ "bootstrap.php";
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
