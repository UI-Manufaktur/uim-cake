module uim.cake.core.plugins.interface_;

@safe:
import uim.cake;

/**
 * Plugin Interface
 *
 * @method void services(uim.cake.Core\IContainer myContainer) Register plugin services to
 *   the application"s container
 */
interface IPlugin {
    // List of valid hooks.
    const String[] VALID_HOOKS = ["bootstrap", "console", "middleware", "routes", "services"];

    // Get the name of this plugin.
    string name();

    // Get the filesystem path to this plugin
    string filesystemPath();

    // Get the filesystem path to configuration for this plugin
    string configPath();

    // Get the filesystem path to configuration for this plugin
    string classPath();

    // Get the filesystem path to templates for this plugin
    string templatePath();

    /**
     * Load all the application configuration and bootstrap logic.
     *
     * The default implementation of this method will include the `config/bootstrap.php` in the plugin if it exist. You
     * can override this method to replace that behavior.
     *
     * The host application is provided as an argument. This allows you to load additional
     * plugin dependencies, or attach events.
     *
     * @param uim.cake.Core\IPluginApplication $app The host application
     */
    void bootstrap(IPluginApplication $app);

    /**
     * Add console commands for the plugin.
     *
     * @param uim.cake.Console\CommandCollection someCommands The command collection to update
     * @return uim.cake.Console\CommandCollection
     */
    CommandCollection console(CommandCollection someCommands);

    /**
     * Add middleware for the plugin.
     *
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to update.
     * @return uim.cake.http.MiddlewareQueue
     */
    MiddlewareQueue middleware(MiddlewareQueue $middlewareQueue);

    /**
     * Add routes for the plugin.
     *
     * The default implementation of this method will include the `config/routes.php` in the plugin if it exists. You
     * can override this method to replace that behavior.
     *
     * @param uim.cake.Routing\RouteBuilder $routes The route builder to update.
     */
    IPlugin routes(RouteBuilder $routes);

    /**
     * Disables the named hook
     *
     * @param string hook The hook to disable
     */
    IPlugin disable(string hook);

    /**
     * Enables the named hook
     *
     * @param string hook The hook to disable
     */
    IPlugin enable(string hook);

    /**
     * Check if the named hook is enabled
     *
     * @param string hook The hook to check
     */
    bool isEnabled(string hook);
}
