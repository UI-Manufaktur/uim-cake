

/**
 * UIM(tm) : Rapid Development Framework (https://UIM.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 */module uim.cake.core;

import uim.cake.console.commandCollection;
import uim.caketps\MiddlewareQueue;
import uim.cakeutings\RouteBuilder;

/**
 * Plugin Interface
 *
 * @method void services(\Cake\Core\IContainer myContainer) Register plugin services to
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
     */
    string getName();

    /**
     * Get the filesystem path to this plugin
     */
    string getPath();

    /**
     * Get the filesystem path to configuration for this plugin
     */
    string getConfigPath();

    /**
     * Get the filesystem path to configuration for this plugin
     */
    string getClassPath();

    /**
     * Get the filesystem path to templates for this plugin
     */
    string getTemplatePath();

    /**
     * Load all the application configuration and bootstrap logic.
     *
     * The default implementation of this method will include the `config/bootstrap.php` in the plugin if it exist. You
     * can override this method to replace that behavior.
     *
     * The host application is provided as an argument. This allows you to load additional
     * plugin dependencies, or attach events.
     *
     * @param \Cake\Core\PluginApplicationInterface $app The host application
     */
    void bootstrap(PluginApplicationInterface $app);

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
     */
    void routes(RouteBuilder $routes);

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
     */
    bool isEnabled(string $hook);
}
