/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core;

@safe:
import uim.cake;

/**
 * Plugin Interface
 *
 * @method void services(uim.cake.Core\IContainer $container) Register plugin services to
 *   the application"s container
 */
interface IPlugin {
  // List of valid hooks.
  const string[] VALID_HOOKS = ["bootstrap", "console", "middleware", "routes", "services"];

  // Get the name of this plugin.
  string getName();

  // Get the filesystem path to this plugin
  string getPath();

  // Get the filesystem path to configuration for this plugin
  string getConfigPath();

  // Get the filesystem path to configuration for this plugin
  string getClassPath();

  // Get the filesystem path to templates for this plugin
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
    * @param uim.cake.Core\IPluginApplication $app The host application
    */
  void bootstrap(IPluginApplication $app);

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
  void routes(RouteBuilder $routes);

  /**
    * Disables the named hook
    *
    * @param string aHook The hook to disable
    * @return this
    */
  function disable(string aHook);

  /**
    * Enables the named hook
    *
    * @param string aHook The hook to disable
    * @return this
    */
  function enable(string aHook);

  /**
    * Check if the named hook is enabled
    *
    * @param string aHook The hook to check
    */
  bool isEnabled(string aHook);
}
