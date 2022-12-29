

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Core;

import uim.cake.consoles.CommandCollection;
import uim.cake.Http\MiddlewareQueue;
import uim.cake.Routing\RouteBuilder;

/**
 * Plugin Interface
 *
 * @method void services(\Cake\Core\IContainer $container) Register plugin services to
 *   the application"s container
 */
interface PluginInterface
{
    /**
     * List of valid hooks.
     *
     * @var array<string>
     */
    public const VALID_HOOKS = ["bootstrap", "console", "middleware", "routes", "services"];

    /**
     * Get the name of this plugin.
     *
     * @return string
     */
    function getName(): string;

    /**
     * Get the filesystem path to this plugin
     *
     * @return string
     */
    function getPath(): string;

    /**
     * Get the filesystem path to configuration for this plugin
     *
     * @return string
     */
    function getConfigPath(): string;

    /**
     * Get the filesystem path to configuration for this plugin
     *
     * @return string
     */
    function getClassPath(): string;

    /**
     * Get the filesystem path to templates for this plugin
     *
     * @return string
     */
    function getTemplatePath(): string;

    /**
     * Load all the application configuration and bootstrap logic.
     *
     * The default implementation of this method will include the `config/bootstrap.php` in the plugin if it exist. You
     * can override this method to replace that behavior.
     *
     * The host application is provided as an argument. This allows you to load additional
     * plugin dependencies, or attach events.
     *
     * @param \Cake\Core\IPluginApplication $app The host application
     * @return void
     */
    function bootstrap(IPluginApplication $app): void;

    /**
     * Add console commands for the plugin.
     *
     * @param \Cake\Console\CommandCollection $commands The command collection to update
     * @return \Cake\Console\CommandCollection
     */
    function console(CommandCollection $commands): CommandCollection;

    /**
     * Add middleware for the plugin.
     *
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to update.
     * @return \Cake\Http\MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue;

    /**
     * Add routes for the plugin.
     *
     * The default implementation of this method will include the `config/routes.php` in the plugin if it exists. You
     * can override this method to replace that behavior.
     *
     * @param \Cake\Routing\RouteBuilder $routes The route builder to update.
     * @return void
     */
    function routes(RouteBuilder $routes): void;

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
