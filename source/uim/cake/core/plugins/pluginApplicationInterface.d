module uim.cake.core;

@safe:
import uim.cake;

/**
 * Interface for Applications that leverage plugins & events.
 *
 * Events can be bound to the application event manager during
 * the application"s bootstrap and plugin bootstrap.
 */
interface IPluginApplication : IEventDispatcher
{
    /**
     * Add a plugin to the loaded plugin set.
     *
     * If the named plugin does not exist, or does not define a Plugin class, an
     * instance of `Cake\Core\BasePlugin` will be used. This generated class will have
     * all plugin hooks enabled.
     *
     * @param uim.cake.Core\IPlugin|string myName The plugin name or plugin object.
     * @param array<string, mixed> myConfig The configuration data for the plugin if using a string for myName
     * @return this
     */
    function addPlugin(myName, array myConfig = []);

    /**
     * Run bootstrap logic for loaded plugins.
     *
     */
    void pluginBootstrap();

    /**
     * Run routes hooks for loaded plugins
     *
     * @param uim.cake.Routing\RouteBuilder $routes The route builder to use.
     * @return uim.cake.Routing\RouteBuilder
     */
    function pluginRoutes(RouteBuilder $routes): RouteBuilder;

    /**
     * Run middleware hooks for plugins
     *
     * @param uim.cake.Http\MiddlewareQueue $middleware The MiddlewareQueue to use.
     * @return uim.cake.Http\MiddlewareQueue
     */
    function pluginMiddleware(MiddlewareQueue $middleware): MiddlewareQueue;

    /**
     * Run console hooks for plugins
     *
     * @param uim.cake.Console\CommandCollection $commands The CommandCollection to use.
     * @return uim.cake.Console\CommandCollection
     */
    CommandCollection pluginConsole(CommandCollection $commands);
}
