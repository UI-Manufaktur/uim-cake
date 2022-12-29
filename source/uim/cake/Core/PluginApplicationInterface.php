


 *


 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Core;

import uim.cake.consoles.CommandCollection;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.https.MiddlewareQueue;
import uim.cake.Routing\RouteBuilder;

/**
 * Interface for Applications that leverage plugins & events.
 *
 * Events can be bound to the application event manager during
 * the application"s bootstrap and plugin bootstrap.
 */
interface IPluginApplication : EventDispatcherInterface
{
    /**
     * Add a plugin to the loaded plugin set.
     *
     * If the named plugin does not exist, or does not define a Plugin class, an
     * instance of `Cake\Core\BasePlugin` will be used. This generated class will have
     * all plugin hooks enabled.
     *
     * @param \Cake\Core\PluginInterface|string $name The plugin name or plugin object.
     * @param array<string, mixed> $config The configuration data for the plugin if using a string for $name
     * @return this
     */
    function addPlugin($name, array $config = []);

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
