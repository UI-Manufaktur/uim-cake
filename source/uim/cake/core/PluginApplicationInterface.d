module uim.cakere;

import uim.cake.console.commandCollection;
import uim.cakeents\IEventDispatcher;
import uim.caketps\MiddlewareQueue;
import uim.cakeutings\RouteBuilder;

/**
 * Interface for Applications that leverage plugins & events.
 *
 * Events can be bound to the application event manager during
 * the application"s bootstrap and plugin bootstrap.
 */
interface PluginApplicationInterface : IEventDispatcher
{
    /**
     * Add a plugin to the loaded plugin set.
     *
     * If the named plugin does not exist, or does not define a Plugin class, an
     * instance of `Cake\Core\BasePlugin` will be used. This generated class will have
     * all plugin hooks enabled.
     *
     * @param \Cake\Core\PluginInterface|string myName The plugin name or plugin object.
     * @param array<string, mixed> myConfig The configuration data for the plugin if using a string for myName
     * @return this
     */
    function addPlugin(myName, array myConfig = []);

    /**
     * Run bootstrap logic for loaded plugins.
     *
     * @return void
     */
    function pluginBootstrap(): void;

    /**
     * Run routes hooks for loaded plugins
     *
     * @param \Cake\Routing\RouteBuilder $routes The route builder to use.
     * @return \Cake\Routing\RouteBuilder
     */
    function pluginRoutes(RouteBuilder $routes): RouteBuilder;

    /**
     * Run middleware hooks for plugins
     *
     * @param \Cake\Http\MiddlewareQueue $middleware The MiddlewareQueue to use.
     * @return \Cake\Http\MiddlewareQueue
     */
    function pluginMiddleware(MiddlewareQueue $middleware): MiddlewareQueue;

    /**
     * Run console hooks for plugins
     *
     * @param \Cake\Console\CommandCollection $commands The CommandCollection to use.
     * @return \Cake\Console\CommandCollection
     */
    function pluginConsole(CommandCollection $commands): CommandCollection;
}
