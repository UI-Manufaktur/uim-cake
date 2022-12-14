/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core;

@safe:
import uim.cake;

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
     * @var array<uim.cake.Core\IPlugin>
     */
    protected $plugins = null;

    /**
     * Names of plugins
     *
     * @var array<string>
     */
    protected $names = null;

    /**
     * Iterator position stack.
     *
     * @var array<int>
     */
    protected $positions = null;

    /**
     * Loop depth
     */
    protected int $loopDepth = -1;

    /**
     * Constructor
     *
     * @param array<uim.cake.Core\IPlugin> $plugins The map of plugins to add to the collection.
     */
    this(array $plugins = null) {
        foreach ($plugins as $plugin) {
            this.add($plugin);
        }
        this.loadConfig();
    }

    /**
     * Load the path information stored in vendor/cakephp-plugins.php
     *
     * This file is generated by the cakephp/plugin-installer package and used
     * to locate plugins on the filesystem as applications can use `extra.plugin-paths`
     * in their composer.json file to move plugin outside of vendor/
     *
     * @internal
     */
    protected void loadConfig() {
        if (Configure::check("plugins")) {
            return;
        }
        $vendorFile = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR ~ "cakephp-plugins.php";
        if (!is_file($vendorFile)) {
            $vendorFile = dirname(dirname(dirname(dirname(__DIR__)))) . DIRECTORY_SEPARATOR ~ "cakephp-plugins.php";
            if (!is_file($vendorFile)) {
                Configure::write(["plugins": []]);

                return;
            }
        }

        aConfig = require $vendorFile;
        Configure::write(aConfig);
    }

    /**
     * Locate a plugin path by looking at configuration data.
     *
     * This will use the `plugins` Configure key, and fallback to enumerating `App::path("plugins")`
     *
     * This method is not part of the official API as plugins with
     * no plugin class are being phased out.
     *
     * @param string aName The plugin name to locate a path for.
     * @return string
     * @throws uim.cake.Core\exceptions.MissingPluginException when a plugin path cannot be resolved.
     * @internal
     */
    string findPath(string aName) {
        // Ensure plugin config is loaded each time. This is necessary primarily
        // for testing because the Configure::clear() call in TestCase::tearDown()
        // wipes out all configuration including plugin paths config.
        this.loadConfig();

        $path = Configure::read("plugins." ~ aName);
        if ($path) {
            return $path;
        }

        $pluginPath = replace("/", DIRECTORY_SEPARATOR, aName);
        $paths = App::path("plugins");
        foreach ($paths as $path) {
            if (is_dir($path . $pluginPath)) {
                return $path . $pluginPath . DIRECTORY_SEPARATOR;
            }
        }

        throw new MissingPluginException(["plugin": aName]);
    }

    /**
     * Add a plugin to the collection
     *
     * Plugins will be keyed by their names.
     *
     * @param uim.cake.Core\IPlugin $plugin The plugin to load.
     * @return this
     */
    function add(IPlugin $plugin) {
        auto myName = $plugin.getName();
        this.plugins[myName] = $plugin;
        this.names = array_keys(this.plugins);

        return this;
    }

    /**
     * Remove a plugin from the collection if it exists.
     *
     * @param string aName The named plugin.
     * @return this
     */
    function remove(string aName) {
        unset(this.plugins[aName]);
        this.names = array_keys(this.plugins);

        return this;
    }

    /**
     * Remove all plugins from the collection
     *
     * @return this
     */
    function clear() {
        this.plugins = null;
        this.names = null;
        this.positions = null;
        this.loopDepth = -1;

        return this;
    }

    /**
     * Check whether the named plugin exists in the collection.
     *
     * @param string aName The named plugin.
     */
    bool has(string aName) {
        return isset(this.plugins[aName]);
    }

    /**
     * Get the a plugin by name.
     *
     * If a plugin isn"t already loaded it will be autoloaded on first access
     * and that plugins loaded this way may miss some hook methods.
     *
     * @param string aName The plugin to get.
     * @return uim.cake.Core\IPlugin The plugin.
     * @throws uim.cake.Core\exceptions.MissingPluginException when unknown plugins are fetched.
     */
    function get(string aName): IPlugin
    {
        if (this.has(aName)) {
            return this.plugins[aName];
        }

        $plugin = this.create(aName);
        this.add($plugin);

        return $plugin;
    }

    /**
     * Create a plugin instance from a name/classname and configuration.
     *
     * @param string aName The plugin name or classname
     * @param array<string, mixed> aConfig Configuration options for the plugin.
     * @return uim.cake.Core\IPlugin
     * @throws uim.cake.Core\exceptions.MissingPluginException When plugin instance could not be created.
     */
    function create(string aName, Json aConfig = null): IPlugin
    {
        if (strpos(aName, "\\") != false) {
            /** @var uim.cake.Core\IPlugin */
            return new aName(aConfig);
        }

        aConfig += ["name": aName];
        $namespace = replace("/", "\\", aName);

        $className = $namespace ~ "\\" ~ "Plugin";
        // Check for [Vendor/]Foo/Plugin class
        if (!class_exists($className)) {
            $pos = strpos(aName, "/");
            if ($pos == false) {
                $className = $namespace ~ "\\" ~ aName ~ "Plugin";
            } else {
                $className = $namespace ~ "\\" ~ substr(aName, $pos + 1) ~ "Plugin";
            }

            // Check for [Vendor/]Foo/FooPlugin
            if (!class_exists($className)) {
                $className = BasePlugin::class;
                if (empty(aConfig["path"])) {
                    aConfig["path"] = this.findPath(aName);
                }
            }
        }

        /** @var class-string<uim.cake.Core\IPlugin> $className */
        return new $className(aConfig);
    }

    /**
     * Implementation of Countable.
     *
     * Get the number of plugins in the collection.
     */
    size_t count() {
        return count(this.plugins);
    }

    /**
     * Part of Iterator Interface
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
     * @return uim.cake.Core\IPlugin
     */
    function current(): IPlugin
    {
        $position = this.positions[this.loopDepth];
        $name = this.names[$position];

        return this.plugins[$name];
    }

    /**
     * Part of Iterator Interface
     */
    void rewind() {
        this.positions[] = 0;
        this.loopDepth += 1;
    }

    /**
     * Part of Iterator Interface
     */
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
     * @return \Generator<uim.cake.Core\IPlugin> A generator containing matching plugins.
     * @throws \InvalidArgumentException on invalid hooks
     */
    function with(string $hook): Generator
    {
        if (!hasAllValues($hook, IPlugin::VALID_HOOKS, true)) {
            throw new InvalidArgumentException("The `{$hook}` hook is not a known plugin hook.");
        }
        foreach (this as $plugin) {
            if ($plugin.isEnabled($hook)) {
                yield $plugin;
            }
        }
    }
}
