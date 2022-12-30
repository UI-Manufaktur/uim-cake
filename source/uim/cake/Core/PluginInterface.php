

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.6.0
  */
module uim.cake.Core;

import uim.cake.consoles.CommandCollection;
import uim.cake.http.MiddlewareQueue;
import uim.cake.routings.RouteBuilder;

/**
 * Plugin Interface
 *
 * @method void services(uim.cake.Core\IContainer $container) Register plugin services to
 *   the application"s container
 */
interface PluginInterface
{
    /**
     * List of valid hooks.
     *
     * @var array<string>
     */
    const VALID_HOOKS = ["bootstrap", "console", "middleware", "routes", "services"];

    /**
     * Get the name of this plugin.
     */
    string getName(): string;

    /**
     * Get the filesystem path to this plugin
     */
    string getPath(): string;

    /**
     * Get the filesystem path to configuration for this plugin
     */
    string getConfigPath(): string;

    /**
     * Get the filesystem path to configuration for this plugin
     */
    string getClassPath(): string;

    /**
     * Get the filesystem path to templates for this plugin
     */
    string getTemplatePath(): string;

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
    void bootstrap(IPluginApplication $app): void;

    /**
     * Add console commands for the plugin.
     *
     * @param uim.cake.consoles.CommandCollection $commands The command collection to update
     * @return uim.cake.consoles.CommandCollection
     */
    function console(CommandCollection $commands): CommandCollection;

    /**
     * Add middleware for the plugin.
     *
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to update.
     * @return uim.cake.http.MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;

    /**
     * Add routes for the plugin.
     *
     * The default implementation of this method will include the `config/routes.php` in the plugin if it exists. You
     * can override this method to replace that behavior.
     *
     * @param uim.cake.routings.RouteBuilder $routes The route builder to update.
     */
    void routes(RouteBuilder $routes): void;

    /**
     * Disables the named hook
     *
     * @param string $hook The hook to disable
     * @return this
     */
    function disable(string $hook);

    /**
     * Enables the named hook
     *
     * @param string $hook The hook to disable
     * @return this
     */
    function enable(string $hook);

    /**
     * Check if the named hook is enabled
     *
     * @param string $hook The hook to check
     * @return bool
     */
    function isEnabled(string $hook): bool;
}
