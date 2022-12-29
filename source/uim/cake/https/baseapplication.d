module uim.cake.https;

@safe:
import uim.cake;

/**
 * Base class for full-stack applications
 *
 * This class serves as a base class for applications that are using
 * UIM as a full stack framework. If you are only using the Http or Console libraries
 * you should implement the relevant interfaces directly.
 *
 * The application class is responsible for bootstrapping the application,
 * and ensuring that middleware is attached. It is also invoked as the last piece
 * of middleware, and delegates request/response handling to the correct controller.
 */
abstract class BaseApplication :
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
    protected myConfigDir;

    /**
     * Plugin Collection
     *
     * @var uim.cake.Core\PluginCollection
     */
    protected myPlugins;

    /**
     * Controller factory
     *
     * @var uim.cake.http.IControllerFactory|null
     */
    protected controllerFactory;

    /**
     * Container
     *
     * @var uim.cake.Core\IContainer|null
     */
    protected myContainer;

    /**
     * Constructor
     *
     * @param string myConfigDir The directory the bootstrap configuration is held in.
     * @param uim.cake.events.IEventManager|null myEventManager Application event manager instance.
     * @param uim.cake.http.IControllerFactory|null $controllerFactory Controller factory.
     */
    this(
        string myConfigDir,
        ?IEventManager myEventManager = null,
        ?IControllerFactory $controllerFactory = null
    ) {
        this.configDir = rtrim(myConfigDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        this.plugins = Plugin::getCollection();
        _eventManager = myEventManager ?: EventManager::instance();
        this.controllerFactory = $controllerFactory;
    }

    /**
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return uim.cake.http.MiddlewareQueue
     */
    abstract MiddlewareQueue middleware(MiddlewareQueue $middlewareQueue);


    MiddlewareQueue pluginMiddleware(MiddlewareQueue $middleware) {
        foreach (this.plugins.with("middleware") as myPlugin) {
            $middleware = myPlugin.middleware($middleware);
        }

        return $middleware;
    }


    function addPlugin(myName, array myConfig = []) {
        if (is_string(myName)) {
            myPlugin = this.plugins.create(myName, myConfig);
        } else {
            myPlugin = myName;
        }
        this.plugins.add(myPlugin);

        return this;
    }

    /**
     * Add an optional plugin
     *
     * If it isn"t available, ignore it.
     *
     * @param uim.cake.Core\IPlugin|string myName The plugin name or plugin object.
     * @param array<string, mixed> myConfig The configuration data for the plugin if using a string for myName
     * @return this
     */
    function addOptionalPlugin(myName, array myConfig = []) {
        try {
            this.addPlugin(myName, myConfig);
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
    PluginCollection getPlugins() {
        return this.plugins;
    }


    void bootstrap() {
        require_once this.configDir . "bootstrap.php";
    }


    void pluginBootstrap() {
        foreach (this.plugins.with("bootstrap") as myPlugin) {
            myPlugin.bootstrap(this);
        }
    }

    /**
     * {@inheritDoc}
     *
     * By default, this will load `config/routes.php` for ease of use and backwards compatibility.
     *
     * @param uim.cake.Routing\RouteBuilder $routes A route builder to add routes into.
     */
    void routes(RouteBuilder $routes) {
      // Only load routes if the router is empty
      if (!Router::routes()) {
        $return = require this.configDir . "routes.php";
        if ($return instanceof Closure) {
            $return($routes);
        }
      }
    }

    RouteBuilder pluginRoutes(RouteBuilder $routes) {
        foreach (this.plugins.with("routes") as myPlugin) {
            myPlugin.routes($routes);
        }

        return $routes;
    }

    /**
     * Define the console commands for an application.
     *
     * By default, all commands in UIM, plugins and the application will be
     * loaded using conventions based names.
     *
     * @param uim.cake.consoles.CommandCollection $commands The CommandCollection to add commands into.
     * @return uim.cake.consoles.CommandCollection The updated collection.
     */
    CommandCollection console(CommandCollection $commands) {
        return $commands.addMany($commands.autoDiscover());
    }


    CommandCollection pluginConsole(CommandCollection $commands) {
        foreach (this.plugins.with("console") as myPlugin) {
            $commands = myPlugin.console($commands);
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
    IContainer getContainer() {
        if (this.container is null) {
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
    protected IContainer buildContainer() {
        myContainer = new Container();
        this.services(myContainer);
        foreach (this.plugins.with("services") as myPlugin) {
            myPlugin.services(myContainer);
        }

        myEvent = this.dispatchEvent("Application.buildContainer", ["container":myContainer]);
        if (myEvent.getResult() instanceof IContainer) {
            return myEvent.getResult();
        }

        return myContainer;
    }

    /**
     * Register application container services.
     *
     * @param uim.cake.Core\IContainer myContainer The Container to update.
     */
    void services(IContainer myContainer) {
    }

    /**
     * Invoke the application.
     *
     * - Convert the PSR response into UIM equivalents.
     * - Create the controller that will handle this request.
     * - Invoke the controller.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request
     * @return \Psr\Http\Message\IResponse
     */
    IResponse handle(
        IServerRequest myRequest
    )  {
        if (this.controllerFactory is null) {
            this.controllerFactory = new ControllerFactory(this.getContainer());
        }

        if (Router::getRequest() != myRequest) {
            Router::setRequest(myRequest);
        }

        $controller = this.controllerFactory.create(myRequest);

        return this.controllerFactory.invoke($controller);
    }
}
