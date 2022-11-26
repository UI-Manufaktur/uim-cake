module uim.cake.core;

/**
 * Plugin is used to load and locate plugins.
 *
 * It also can retrieve plugin paths and load their bootstrap and routes files.
 *
 * @link https://book.UIM.org/4/en/plugins.html
 */
class Plugin
{
    /**
     * Holds a list of all loaded plugins and their configuration
     *
     * @var \Cake\Core\PluginCollection|null
     */
    protected static myPlugins;

    /**
     * Returns the filesystem path for a plugin
     *
     * @param string myName name of the plugin in CamelCase format
     * @return string path to the plugin folder
     * @throws \Cake\Core\Exception\MissingPluginException If the folder for plugin was not found
     *   or plugin has not been loaded.
     */
    static string path(string myName) {
        myPlugin = static::getCollection().get(myName);
        return myPlugin.getPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing class files.
     *
     * @param string myName name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing class files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    static string classPath(string myName) {
        myPlugin = static::getCollection().get(myName);

        return myPlugin.getClassPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing config files.
     *
     * @param string myName name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing config files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    static string configPath(string myName) {
        myPlugin = static::getCollection().get(myName);

        return myPlugin.getConfigPath();
    }

    /**
     * Returns the filesystem path for plugin"s folder containing template files.
     *
     * @param string myName name of the plugin in CamelCase format.
     * @return string Path to the plugin folder containing template files.
     * @throws \Cake\Core\Exception\MissingPluginException If plugin has not been loaded.
     */
    static string templatePath(string myName) {
        myPlugin = static::getCollection().get(myName);

        return myPlugin.getTemplatePath();
    }

    /**
     * Returns true if the plugin myPlugin is already loaded.
     *
     * @param string myPlugin Plugin name.
     * @return bool

     */
    static bool isLoaded(string myPlugin) {
        return static::getCollection().has(myPlugin);
    }

    /**
     * Return a list of loaded plugins.
     *
     * @return array<string> A list of plugins that have been loaded
     */
    static function loaded(): array
    {
        string[] myNames;
        foreach (static::getCollection() as myPlugin) {
            myNames[] = myPlugin.getName();
        }
        sort(myNames);

        return myNames;
    }

    /**
     * Get the shared plugin collection.
     *
     * This method should generally not be used during application
     * runtime as plugins should be set during Application startup.
     *
     * @return \Cake\Core\PluginCollection
     */
    static auto getCollection(): PluginCollection
    {
        if (!isset(static::myPlugins)) {
            static::myPlugins = new PluginCollection();
        }

        return static::myPlugins;
    }
}
