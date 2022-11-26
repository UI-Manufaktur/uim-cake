

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.https;

import uim.cake.console.commandCollection;
import uim.cake.controller\ControllerFactory;
import uim.cake.core.ConsoleApplicationInterface;
import uim.cake.core.Container;
import uim.cake.core.ContainerApplicationInterface;
import uim.cake.core.IContainer;
import uim.cake.core.exceptions\MissingPluginException;
import uim.cake.core.HttpApplicationInterface;
import uim.cake.core.Plugin;
import uim.cake.core.PluginApplicationInterface;
import uim.cake.core.PluginCollection;
import uim.cake.events\EventDispatcherTrait;
import uim.cake.events\EventManager;
import uim.cake.events\IEventManager;
import uim.cake.routings\RouteBuilder;
import uim.cake.routings\Router;
import uim.cake.routings\RoutingApplicationInterface;
use Closure;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

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
abstract class BaseApplication :
    ConsoleApplicationInterface,
    ContainerApplicationInterface,
    HttpApplicationInterface,
    PluginApplicationInterface,
    RoutingApplicationInterface
{
    use EventDispatcherTrait;

    /**
     * @var string Contains the path of the config directory
     */
    protected myConfigDir;

    /**
     * Plugin Collection
     *
     * @var \Cake\Core\PluginCollection
     */
    protected myPlugins;

    /**
     * Controller factory
     *
     * @var \Cake\Http\IControllerFactory|null
     */
    protected $controllerFactory;

    /**
     * Container
     *
     * @var \Cake\Core\IContainer|null
     */
    protected myContainer;

    /**
     * Constructor
     *
     * @param string myConfigDir The directory the bootstrap configuration is held in.
     * @param \Cake\Event\IEventManager|null myEventManager Application event manager instance.
     * @param \Cake\Http\IControllerFactory|null $controllerFactory Controller factory.
     */
    this(
        string myConfigDir,
        ?IEventManager myEventManager = null,
        ?IControllerFactory $controllerFactory = null
    ) {
        this.configDir = rtrim(myConfigDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        this.plugins = Plugin::getCollection();
        this._eventManager = myEventManager ?: EventManager::instance();
        this.controllerFactory = $controllerFactory;
    }

    /**
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return \Cake\Http\MiddlewareQueue
     */
    abstract function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;


    function pluginMiddleware(MiddlewareQueue $middleware): MiddlewareQueue
    {
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
     * @param \Cake\Core\PluginInterface|string myName The plugin name or plugin object.
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
     * @return \Cake\Core\PluginCollection
     */
    auto getPlugins(): PluginCollection
    {
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
     * @param \Cake\Routing\RouteBuilder $routes A route builder to add routes into.
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


    function pluginRoutes(RouteBuilder $routes): RouteBuilder
    {
        foreach (this.plugins.with("routes") as myPlugin) {
            myPlugin.routes($routes);
        }

        return $routes;
    }

    /**
     * Define the console commands for an application.
     *
     * By default, all commands in CakePHP, plugins and the application will be
     * loaded using conventions based names.
     *
     * @param \Cake\Console\CommandCollection $commands The CommandCollection to add commands into.
     * @return \Cake\Console\CommandCollection The updated collection.
     */
    function console(CommandCollection $commands): CommandCollection
    {
        return $commands.addMany($commands.autoDiscover());
    }


    function pluginConsole(CommandCollection $commands): CommandCollection
    {
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
     * @return \Cake\Core\IContainer
     */
    auto getContainer(): IContainer
    {
        if (this.container === null) {
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
     * @return \Cake\Core\IContainer
     */
    protected auto buildContainer(): IContainer
    {
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
     * @param \Cake\Core\IContainer myContainer The Container to update.
     */
    void services(IContainer myContainer) {
    }

    /**
     * Invoke the application.
     *
     * - Convert the PSR response into CakePHP equivalents.
     * - Create the controller that will handle this request.
     * - Invoke the controller.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request
     * @return \Psr\Http\Message\IResponse
     */
    function handle(
        IServerRequest myRequest
    ): IResponse {
        if (this.controllerFactory === null) {
            this.controllerFactory = new ControllerFactory(this.getContainer());
        }

        if (Router::getRequest() !== myRequest) {
            Router::setRequest(myRequest);
        }

        $controller = this.controllerFactory.create(myRequest);

        return this.controllerFactory.invoke($controller);
    }
}
