module uim.cake.core;

import uim.cake.core.exceptions\MissingPluginException;
use Countable;
use Generator;
use InvalidArgumentException;
use Iterator;

/**
 * Plugin Collection
 *
 * Holds onto plugin objects loaded into an application, and
 * provides methods for iterating, and finding plugins based
 * on criteria.
 *
 * This class : the Iterator interface to allow plugins
 * to be iterated, handling the situation where a plugin"s hook
 * method (usually bootstrap) loads another plugin during iteration.
 *
 * While its implementation supported nested iteration it does not
 * support using `continue` or `break` inside loops.
 */
class PluginCollection : Iterator, Countable
{
    /**
     * Plugin list
     *
     * @var array<\Cake\Core\PluginInterface>
     */
    protected myPlugins = [];

    /**
     * Names of plugins
     *
     * @var array<string>
     */
    protected myNames = [];

    /**
     * Iterator position stack.
     *
     * @var array<int>
     */
    protected $positions = [];

    /**
     * Loop depth
     *
     * @var int
     */
    protected $loopDepth = -1;

    /**
     * Constructor
     *
     * @param array<\Cake\Core\PluginInterface> myPlugins The map of plugins to add to the collection.
     */
    this(array myPlugins = []) {
        foreach (myPlugins as myPlugin) {
            this.add(myPlugin);
        }
        this.loadConfig();
    }

    /**
     * Load the path information stored in vendor/UIM-plugins.php
     *
     * This file is generated by the UIM/plugin-installer package and used
     * to locate plugins on the filesystem as applications can use `extra.plugin-paths`
     * in their composer.json file to move plugin outside of vendor/
     *
     * @internal
     */
    protected void loadConfig() {
        if (Configure::check("plugins")) {
            return;
        }
        $vendorFile = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR . "UIM-plugins.php";
        if (!is_file($vendorFile)) {
            $vendorFile = dirname(dirname(dirname(dirname(__DIR__)))) . DIRECTORY_SEPARATOR . "UIM-plugins.php";
            if (!is_file($vendorFile)) {
                Configure.write(["plugins" => []]);

                return;
            }
        }

        myConfig = require $vendorFile;
        Configure.write(myConfig);
    }

    /**
     * Locate a plugin path by looking at configuration data.
     *
     * This will use the `plugins` Configure key, and fallback to enumerating `App::path("plugins")`
     *
     * This method is not part of the official public API as plugins with
     * no plugin class are being phased out.
     *
     * @param string myName The plugin name to locate a path for. Will return "" when a plugin cannot be found.
     * @return string
     * @throws \Cake\Core\Exception\MissingPluginException when a plugin path cannot be resolved.
     * @internal
     */
    string findPath(string myName) {
        // Ensure plugin config is loaded each time. This is necessary primarily
        // for testing because the Configure::clear() call in TestCase::tearDown()
        // wipes out all configuration including plugin paths config.
        this.loadConfig();

        myPath = Configure::read("plugins." . myName);
        if (myPath) { return myPath; }

        myPluginPath = str_replace("/", DIRECTORY_SEPARATOR, myName);
        myPaths = App::path("plugins");
        foreach (myPaths as myPath) {
            if (is_dir(myPath . myPluginPath)) {
                return myPath . myPluginPath . DIRECTORY_SEPARATOR;
            }
        }

        throw new MissingPluginException(["plugin" => myName]);
    }

    /**
     * Add a plugin to the collection
     *
     * Plugins will be keyed by their names.
     *
     * @param \Cake\Core\PluginInterface myPlugin The plugin to load.
     * @return this
     */
    function add(PluginInterface myPlugin) {
        myName = myPlugin.getName();
        this.plugins[myName] = myPlugin;
        this.names = array_keys(this.plugins);

        return this;
    }

    /**
     * Remove a plugin from the collection if it exists.
     *
     * @param string myName The named plugin.
     * @return this
     */
    function remove(string myName) {
        unset(this.plugins[myName]);
        this.names = array_keys(this.plugins);

        return this;
    }

    // Remove all plugins from the collection
    O clear(this O)() {
        this.plugins = [];
        this.names = [];
        this.positions = [];
        this.loopDepth = -1;

        return cast(O)this;
    }

    /**
     * Check whether the named plugin exists in the collection.
     *
     * @param string myName The named plugin.
     */
    bool has(string myName) {
        return isset(this.plugins[myName]);
    }

    /**
     * Get the a plugin by name.
     *
     * If a plugin isn"t already loaded it will be autoloaded on first access
     * and that plugins loaded this way may miss some hook methods.
     *
     * @param string myName The plugin to get.
     * @return \Cake\Core\PluginInterface The plugin.
     * @throws \Cake\Core\Exception\MissingPluginException when unknown plugins are fetched.
     */
    PluginInterface get(string myName) {
        if (this.has(myName)) {
            return this.plugins[myName];
        }

        myPlugin = this.create(myName);
        this.add(myPlugin);

        return myPlugin;
    }

    /**
     * Create a plugin instance from a name/classname and configuration.
     *
     * @param string myName The plugin name or classname
     * @param array<string, mixed> myConfig Configuration options for the plugin.
     * @return \Cake\Core\PluginInterface
     * @throws \Cake\Core\Exception\MissingPluginException When plugin instance could not be created.
     */
    function create(string myName, array myConfig = []): PluginInterface
    {
        if (strpos(myName, "\\") !== false) {
            /** @var \Cake\Core\PluginInterface */
            return new myName(myConfig);
        }

        myConfig += ["name" => myName];
        /** @var class-string<\Cake\Core\PluginInterface> myClassName */
        myClassName = str_replace("/", "\\", myName) . "\\" . "Plugin";
        if (!class_exists(myClassName)) {
            myClassName = BasePlugin::class;
            if (empty(myConfig["path"])) {
                myConfig["path"] = this.findPath(myName);
            }
        }

        return new myClassName(myConfig);
    }

    /**
     * Implementation of Countable.
     *
     * Get the number of plugins in the collection.
     */
    int count() {
        return count(this.plugins);
    }

    /**
     * Part of Iterator Interface
     *
     */
    void next() {
        this.positions[this.loopDepth]++;
    }

    /**
     * Part of Iterator Interface
     */
    string key() {
        return this.names[this.positions[this.loopDepth]];
    }

    /**
     * Part of Iterator Interface
     *
     * @return \Cake\Core\PluginInterface
     */
    function current(): PluginInterface
    {
        $position = this.positions[this.loopDepth];
        myName = this.names[$position];

        return this.plugins[myName];
    }

    /**
     * Part of Iterator Interface
     *
     */
    void rewind() {
        this.positions[] = 0;
        this.loopDepth += 1;
    }

    /**
     * Part of Iterator Interface
    bool valid() {
        $valid = isset(this.names[this.positions[this.loopDepth]]);
        if (!$valid) {
            array_pop(this.positions);
            this.loopDepth -= 1;
        }

        return $valid;
    }

    /**
     * Filter the plugins to those with the named hook enabled.
     *
     * @param string $hook The hook to filter plugins by
     * @return \Generator<\Cake\Core\PluginInterface> A generator containing matching plugins.
     * @throws \InvalidArgumentException on invalid hooks
     */
    function with(string $hook): Generator
    {
        if (!in_array($hook, PluginInterface::VALID_HOOKS, true)) {
            throw new InvalidArgumentException("The `{$hook}` hook is not a known plugin hook.");
        }
        foreach (this as myPlugin) {
            if (myPlugin.isEnabled($hook)) {
                yield myPlugin;
            }
        }
    }
}
