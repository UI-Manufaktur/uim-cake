


 *


 * @since         3.3.0
  */
module uim.cake.Http;

import uim.cake.consoles.CommandCollection;
import uim.cake.controllers.ControllerFactory;
import uim.cake.core.IConsoleApplication;
import uim.cake.core.Container;
import uim.cake.core.IContainerApplication;
import uim.cake.core.IContainer;
import uim.cake.core.exceptions.MissingPluginException;
import uim.cake.core.IHttpApplication;
import uim.cake.core.Plugin;
import uim.cake.core.IPluginApplication;
import uim.cake.core.PluginCollection;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.events.EventManager;
import uim.cake.events.IEventManager;
import uim.cake.routings.RouteBuilder;
import uim.cake.routings.Router;
import uim.cake.routings.IRoutingApplication;
use Closure;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

/**
 * Base class for full-stack applications
 *
 * This class serves as a base class for applications that are using
 * CakePHP as a full stack framework. If you are only using the Http or Console libraries
 * you should implement the relevant interfaces directly.
 *
 * The application class is responsible for bootstrapping the application,
 * and ensuring that middleware is attached. It is also invoked as the last piece
 * of middleware, and delegates request/response handling to the correct controller.
 */
abstract class BaseApplication implements
    IConsoleApplication,
    IContainerApplication,
    IHttpApplication,
    IPluginApplication,
    IRoutingApplication
{
    use EventDispatcherTrait;

    /**
     * @var string Contains the path of the config directory
     */
    protected $configDir;

    /**
     * Plugin Collection
     *
     * @var uim.cake.Core\PluginCollection
     */
    protected $plugins;

    /**
     * Controller factory
     *
     * @var uim.cake.http.ControllerFactoryInterface|null
     */
    protected $controllerFactory;

    /**
     * Container
     *
     * @var uim.cake.Core\IContainer|null
     */
    protected $container;

    /**
     * Constructor
     *
     * @param string $configDir The directory the bootstrap configuration is held in.
     * @param uim.cake.events.IEventManager|null $eventManager Application event manager instance.
     * @param uim.cake.http.ControllerFactoryInterface|null $controllerFactory Controller factory.
     */
    this(
        string $configDir,
        ?IEventManager $eventManager = null,
        ?ControllerFactoryInterface $controllerFactory = null
    ) {
        this.configDir = rtrim($configDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        this.plugins = Plugin::getCollection();
        _eventManager = $eventManager ?: EventManager::instance();
        this.controllerFactory = $controllerFactory;
    }

    /**
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return uim.cake.http.MiddlewareQueue
     */
    abstract function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;


    function pluginMiddleware(MiddlewareQueue $middleware): MiddlewareQueue
    {
        foreach (this.plugins.with("middleware") as $plugin) {
            $middleware = $plugin.middleware($middleware);
        }

        return $middleware;
    }


    function addPlugin($name, array $config = []) {
        if (is_string($name)) {
            $plugin = this.plugins.create($name, $config);
        } else {
            $plugin = $name;
        }
        this.plugins.add($plugin);

        return this;
    }

    /**
     * Add an optional plugin
     *
     * If it isn"t available, ignore it.
     *
     * @param uim.cake.Core\IPlugin|string aName The plugin name or plugin object.
     * @param array<string, mixed> $config The configuration data for the plugin if using a string for $name
     * @return this
     */
    function addOptionalPlugin($name, array $config = []) {
        try {
            this.addPlugin($name, $config);
        } catch (MissingPluginException $e) {
            // Do not halt if the plugin is missing
        }

        return this;
    }

    /**
     * Get the plugin collection in use.
     *
     * @return uim.cake.Core\PluginCollection
     */
    function getPlugins(): PluginCollection
    {
        return this.plugins;
    }


    function bootstrap(): void
    {
        require_once this.configDir ~ "bootstrap.php";
    }


    function pluginBootstrap(): void
    {
        foreach (this.plugins.with("bootstrap") as $plugin) {
            $plugin.bootstrap(this);
        }
    }

    /**
     * {@inheritDoc}
     *
     * By default, this will load `config/routes.php` for ease of use and backwards compatibility.
     *
     * @param uim.cake.routings.RouteBuilder $routes A route builder to add routes into.
     */
    void routes(RouteBuilder $routes): void
    {
        // Only load routes if the router is empty
        if (!Router::routes()) {
            $return = require this.configDir ~ "routes.php";
            if ($return instanceof Closure) {
                $return($routes);
            }
        }
    }


    function pluginRoutes(RouteBuilder $routes): RouteBuilder
    {
        foreach (this.plugins.with("routes") as $plugin) {
            $plugin.routes($routes);
        }

        return $routes;
    }

    /**
     * Define the console commands for an application.
     *
     * By default, all commands in CakePHP, plugins and the application will be
     * loaded using conventions based names.
     *
     * @param uim.cake.consoles.CommandCollection $commands The CommandCollection to add commands into.
     * @return uim.cake.consoles.CommandCollection The updated collection.
     */
    function console(CommandCollection $commands): CommandCollection
    {
        return $commands.addMany($commands.autoDiscover());
    }


    function pluginConsole(CommandCollection $commands): CommandCollection
    {
        foreach (this.plugins.with("console") as $plugin) {
            $commands = $plugin.console($commands);
        }

        return $commands;
    }

    /**
     * Get the dependency injection container for the application.
     *
     * The first time the container is fetched it will be constructed
     * and stored for future calls.
     *
     * @return uim.cake.Core\IContainer
     */
    function getContainer(): IContainer
    {
        if (this.container == null) {
            this.container = this.buildContainer();
        }

        return this.container;
    }

    /**
     * Build the service container
     *
     * Override this method if you need to use a custom container or
     * want to change how the container is built.
     *
     * @return uim.cake.Core\IContainer
     */
    protected function buildContainer(): IContainer
    {
        $container = new Container();
        this.services($container);
        foreach (this.plugins.with("services") as $plugin) {
            $plugin.services($container);
        }

        $event = this.dispatchEvent("Application.buildContainer", ["container": $container]);
        if ($event.getResult() instanceof IContainer) {
            return $event.getResult();
        }

        return $container;
    }

    /**
     * Register application container services.
     *
     * @param uim.cake.Core\IContainer $container The Container to update.
     */
    void services(IContainer $container): void
    {
    }

    /**
     * Invoke the application.
     *
     * - Add the request to the container, enabling its injection into other services.
     * - Create the controller that will handle this request.
     * - Invoke the controller.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request
     * @return \Psr\Http\messages.IResponse
     */
    function handle(
        IServerRequest $request
    ): IResponse {
        $container = this.getContainer();
        $container.add(ServerRequest::class, $request);

        if (this.controllerFactory == null) {
            this.controllerFactory = new ControllerFactory($container);
        }

        if (Router::getRequest() != $request) {
            Router::setRequest($request);
        }

        $controller = this.controllerFactory.create($request);

        return this.controllerFactory.invoke($controller);
    }
}
