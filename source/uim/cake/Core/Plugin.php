


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Core;

/**
 * Plugin is used to load and locate plugins.
 *
 * It also can retrieve plugin paths and load their bootstrap and routes files.
 *
 * @link https://book.cakephp.org/4/en/plugins.html
 */
class Plugin
{
    /**
     * Holds a list of all loaded plugins and their configuration
     *
     * @var \Cake\Core\PluginCollection|null
     */
    protected static $plugins;

    /**
     * Returns the filesystem path for a plugin
     *
     * @param string $name name of the plugin in CamelCase format
     * @return string path to the plugin folder
     * @throws \Cake\Core\Exception\MissingPluginException If the folder for plugin was not found
     *   or plugin has not been loaded.
     */
    public static function path(string $name): string
    {
        $plugin = static::getCollection().get($name);

        return $plugin.getPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing class files.
     *
     * @param string $name name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing class files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    public static function classPath(string $name): string
    {
        $plugin = static::getCollection().get($name);

        return $plugin.getClassPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing config files.
     *
     * @param string $name name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing config files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    public static function configPath(string $name): string
    {
        $plugin = static::getCollection().get($name);

        return $plugin.getConfigPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing template files.
     *
     * @param string $name name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing template files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    public static function templatePath(string $name): string
    {
        $plugin = static::getCollection().get($name);

        return $plugin.getTemplatePath();
    }

    /**
     * Returns true if the plugin $plugin is already loaded.
     *
     * @param string $plugin Plugin name.
     * @return bool
     * @since 3.7.0
     */
    public static function isLoaded(string $plugin): bool
    {
        return static::getCollection().has($plugin);
    }

    /**
     * Return a list of loaded plugins.
     *
     * @return array<string> A list of plugins that have been loaded
     */
    public static string[] loaded(): array
    {
        $names = [];
        foreach (static::getCollection() as $plugin) {
            $names[] = $plugin.getName();
        }
        sort($names);

        return $names;
    }

    /**
     * Get the shared plugin collection.
     *
     * This method should generally not be used during application
     * runtime as plugins should be set during Application startup.
     *
     * @return \Cake\Core\PluginCollection
     */
    public static function getCollection(): PluginCollection
    {
        if (!isset(static::$plugins)) {
            static::$plugins = new PluginCollection();
        }

        return static::$plugins;
    }
}
