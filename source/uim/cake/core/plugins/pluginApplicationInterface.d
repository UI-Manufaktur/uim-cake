/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
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
     * @param uim.cake.Core\IPlugin|string aName The plugin name or plugin object.
     * @param array<string, mixed> aConfig The configuration data for the plugin if using a string for $name
     * @return this
     */
    function addPlugin($name, Json aConfig = null);

    /**
     * Run bootstrap logic for loaded plugins.
     */
    void pluginBootstrap();

    /**
     * Run routes hooks for loaded plugins
     *
     * @param uim.cake.routings.RouteBuilder $routes The route builder to use.
     * @return uim.cake.routings.RouteBuilder
     */
    function pluginRoutes(RouteBuilder $routes): RouteBuilder;

    /**
     * Run middleware hooks for plugins
     *
     * @param uim.cake.http.MiddlewareQueue $middleware The MiddlewareQueue to use.
     * @return uim.cake.http.MiddlewareQueue
     */
    function pluginMiddleware(MiddlewareQueue $middleware): MiddlewareQueue;

    /**
     * Run console hooks for plugins
     *
     * @param uim.cake.consoles.CommandCollection $commands The CommandCollection to use.
     * @return uim.cake.consoles.CommandCollection
     */
    function pluginConsole(CommandCollection $commands): CommandCollection;
}
