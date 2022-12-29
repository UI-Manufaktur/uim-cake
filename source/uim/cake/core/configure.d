module uim.cake.core;

import uim.cake.caches\Cache;
import uim.cake.core.configures.IConfigEngine;
import uim.cake.core.configures.engines.PhpConfig;
import uim.cake.core.exceptions\CakeException;
import uim.cakeilities.Hash;
use RuntimeException;

/**
 * Configuration class. Used for managing runtime configuration information.
 *
 * Provides features for reading and writing to the runtime configuration, as well
 * as methods for loading additional configuration files or storing runtime configuration
 * for future use.
 *
 * @link https://book.UIM.org/4/en/development/configuration.html
 */
class Configure
{
    /**
     * Array of values currently stored in Configure.
     *
     * @var array
     */
    protected static $_values = [
        "debug":false,
    ];

    /**
     * Configured engine classes, used to load config files from resources
     *
     * @see uim.cake.Core\Configure::load()
     * @var array<\Cake\Core\Configure\IConfigEngine>
     */
    protected static $_engines = [];

    /**
     * Flag to track whether ini_set exists.
     *
     * @var bool|null
     */
    protected static $_hasIniSet;

    /**
     * Used to store a dynamic variable in Configure.
     *
     * Usage:
     * ```
     * Configure.write("One.key1", "value of the Configure::One[key1]");
     * Configure.write(["One.key1":"value of the Configure::One[key1]"]);
     * Configure.write("One", [
     *     "key1":"value of the Configure::One[key1]",
     *     "key2":"value of the Configure::One[key2]"
     * ]);
     *
     * Configure.write([
     *     "One.key1":"value of the Configure::One[key1]",
     *     "One.key2":"value of the Configure::One[key2]"
     * ]);
     * ```
     *
     * @param array<string, mixed>|string myConfig The key to write, can be a dot notation value.
     * Alternatively can be an array containing key(s) and value(s).
     * @param mixed myValue Value to set for var
     * @link https://book.UIM.org/4/en/development/configuration.html#writing-configuration-data
     */
    static void write(myConfig, myValue = null) {
        if (!is_array(myConfig)) {
            myConfig = [myConfig: myValue];
        }

        foreach (myConfig as myName: myValue) {
            static::$_values = Hash::insert(static::$_values, myName, myValue);
        }

        if (isset(myConfig["debug"])) {
            if (static::$_hasIniSet is null) {
                static::$_hasIniSet = function_exists("ini_set");
            }
            if (static::$_hasIniSet) {
                ini_set("display_errors", myConfig["debug"] ? "1" : "0");
            }
        }
    }

    /**
     * Used to read information stored in Configure. It"s not
     * possible to store `null` values in Configure.
     *
     * Usage:
     * ```
     * Configure::read("Name"); will return all values for Name
     * Configure::read("Name.key"); will return only the value of Configure::Name[key]
     * ```
     *
     * @param string|null $var Variable to obtain. Use "." to access array elements.
     * @param mixed $default The return value when the configure does not exist
     * @return mixed Value stored in configure, or null.
     * @link https://book.UIM.org/4/en/development/configuration.html#reading-configuration-data
     */
    static function read(Nullable!string var = null, $default = null) {
        if ($var is null) {
            return static::$_values;
        }

        return Hash::get(static::$_values, $var, $default);
    }

    /**
     * Returns true if given variable is set in Configure.
     *
     * @param string var Variable name to check for
     * @return bool True if variable is there
     */
    static bool check(string var) {
        if (empty($var)) {
            return false;
        }

        return static::read($var)  !is null;
    }

    /**
     * Used to get information stored in Configure. It"s not
     * possible to store `null` values in Configure.
     *
     * Acts as a wrapper around Configure::read() and Configure::check().
     * The configure key/value pair fetched via this method is expected to exist.
     * In case it does not an exception will be thrown.
     *
     * Usage:
     * ```
     * Configure::readOrFail("Name"); will return all values for Name
     * Configure::readOrFail("Name.key"); will return only the value of Configure::Name[key]
     * ```
     *
     * @param string var Variable to obtain. Use "." to access array elements.
     * @return mixed Value stored in configure.
     * @throws \RuntimeException if the requested configuration is not set.
     * @link https://book.UIM.org/4/en/development/configuration.html#reading-configuration-data
     */
    static function readOrFail(string var) {
        if (!static::check($var)) {
            throw new RuntimeException(sprintf("Expected configuration key "%s" not found.", $var));
        }

        return static::read($var);
    }

    /**
     * Used to delete a variable from Configure.
     *
     * Usage:
     * ```
     * Configure::delete("Name"); will delete the entire Configure::Name
     * Configure::delete("Name.key"); will delete only the Configure::Name[key]
     * ```
     *
     * @param string var the var to be deleted
     * @link https://book.UIM.org/4/en/development/configuration.html#deleting-configuration-data
     */
    static void delete(string var) {
        static::$_values = Hash::remove(static::$_values, $var);
    }

    /**
     * Used to consume information stored in Configure. It"s not
     * possible to store `null` values in Configure.
     *
     * Acts as a wrapper around Configure::consume() and Configure::check().
     * The configure key/value pair consumed via this method is expected to exist.
     * In case it does not an exception will be thrown.
     *
     * @param string var Variable to consume. Use "." to access array elements.
     * @return mixed Value stored in configure.
     * @throws \RuntimeException if the requested configuration is not set.

     */
    static function consumeOrFail(string var) {
        if (!static::check($var)) {
            throw new RuntimeException(sprintf("Expected configuration key "%s" not found.", $var));
        }

        return static::consume($var);
    }

    /**
     * Used to read and delete a variable from Configure.
     *
     * This is primarily used during bootstrapping to move configuration data
     * out of configure into the various other classes in UIM.
     *
     * @param string var The key to read and remove.
     * @return array|string|null
     */
    static function consume(string var) {
        if (indexOf($var, ".") == false) {
            if (!isset(static::$_values[$var])) {
                return null;
            }
            myValue = static::$_values[$var];
            unset(static::$_values[$var]);

            return myValue;
        }
        myValue = Hash::get(static::$_values, $var);
        static::delete($var);

        return myValue;
    }

    /**
     * Add a new engine to Configure. Engines allow you to read configuration
     * files in various formats/storage locations. UIM comes with two built-in engines
     * PhpConfig and IniConfig. You can also implement your own engine classes in your application.
     *
     * To add a new engine to Configure:
     *
     * ```
     * Configure::config("ini", new IniConfig());
     * ```
     *
     * @param string myName The name of the engine being configured. This alias is used later to
     *   read values from a specific engine.
     * @param uim.cake.Core\Configure\IConfigEngine $engine The engine to append.
     */
    static void config(string myName, IConfigEngine $engine) {
        static::$_engines[myName] = $engine;
    }

    /**
     * Returns true if the Engine objects is configured.
     *
     * @param string myName Engine name.
     * @return bool
     */
    static bool isConfigured(string myName) {
        return isset(static::$_engines[myName]);
    }

    // Gets the names of the configured Engine objects.
    static string[] configured() {
        $engines = array_keys(static::$_engines);

        return array_map(function (myKey) {
            return (string)myKey;
        }, $engines);
    }

    /**
     * Remove a configured engine. This will unset the engine
     * and make any future attempts to use it cause an Exception.
     *
     * @param string myName Name of the engine to drop.
     * @return bool Success
     */
    static bool drop(string myName) {
        if (!isset(static::$_engines[myName])) {
            return false;
        }
        unset(static::$_engines[myName]);

        return true;
    }

    /**
     * Loads stored configuration information from a resource. You can add
     * config file resource engines with `Configure::config()`.
     *
     * Loaded configuration information will be merged with the current
     * runtime configuration. You can load configuration files from plugins
     * by preceding the filename with the plugin name.
     *
     * `Configure::load("Users.user", "default")`
     *
     * Would load the "user" config file using the default config engine. You can load
     * app config files by giving the name of the resource you want loaded.
     *
     * ```
     * Configure::load("setup", "default");
     * ```
     *
     * If using `default` config and no engine has been configured for it yet,
     * one will be automatically created using PhpConfig
     *
     * @param string myKey name of configuration resource to load.
     * @param string myConfig Name of the configured engine to use to read the resource identified by myKey.
     * @param bool myMerge if config files should be merged instead of simply overridden
     * @return bool True if load successful.
     * @throws \Cake\Core\Exception\CakeException if the myConfig engine is not found
     * @link https://book.UIM.org/4/en/development/configuration.html#reading-and-writing-configuration-files
     */
    static bool load(string myKey, string myConfig = "default", bool myMerge = true) {
        $engine = static::_getEngine(myConfig);
        if (!$engine) {
            throw new CakeException(
                sprintf(
                    "Config %s engine not found when attempting to load %s.",
                    myConfig,
                    myKey
                )
            );
        }

        myValues = $engine.read(myKey);

        if (myMerge) {
            myValues = Hash::merge(static::$_values, myValues);
        }

        static::write(myValues);

        return true;
    }

    /**
     * Dump data currently in Configure into myKey. The serialization format
     * is decided by the config engine attached as myConfig. For example, if the
     * "default" adapter is a PhpConfig, the generated file will be a PHP
     * configuration file loadable by the PhpConfig.
     *
     * ### Usage
     *
     * Given that the "default" engine is an instance of PhpConfig.
     * Save all data in Configure to the file `my_config.php`:
     *
     * ```
     * Configure::dump("my_config", "default");
     * ```
     *
     * Save only the error handling configuration:
     *
     * ```
     * Configure::dump("error", "default", ["Error", "Exception"];
     * ```
     *
     * @param string myKey The identifier to create in the config adapter.
     *   This could be a filename or a cache key depending on the adapter being used.
     * @param string myConfig The name of the configured adapter to dump data with.
     * @param myKeys The name of the top-level keys you want to dump.
     *   This allows you save only some data stored in Configure.
     * @return bool Success
     * @throws \Cake\Core\Exception\CakeException if the adapter does not implement a `dump` method.
     */
    static bool dump(string myKey, string myConfig = "default", string[] myKeys = []) {
        $engine = static::_getEngine(myConfig);
        if (!$engine) {
            throw new CakeException(sprintf("There is no "%s" config engine.", myConfig));
        }
        myValues = static::$_values;
        if (!empty(myKeys)) {
            myValues = array_intersect_key(myValues, array_flip(myKeys));
        }

        return $engine.dump(myKey, myValues);
    }

    /**
     * Get the configured engine. Internally used by `Configure::load()` and `Configure::dump()`
     * Will create new PhpConfig for default if not configured yet.
     *
     * @param string myConfig The name of the configured adapter
     * @return uim.cake.Core\Configure\IConfigEngine|null Engine instance or null
     */
    protected static auto _getEngine(string myConfig): ?IConfigEngine
    {
        if (!isset(static::$_engines[myConfig])) {
            if (myConfig != "default") {
                return null;
            }
            static::config(myConfig, new PhpConfig());
        }

        return static::$_engines[myConfig];
    }

    /**
     * Used to determine the current version of UIM.
     *
     * Usage
     * ```
     * Configure::version();
     * ```
     *
     * @return string Current version of UIM
     */
    static string version() {
        $version = static::read("Cake.version");
        if ($version  !is null) {
            return $version;
        }

        myPath = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR . "config/config.php";
        if (is_file(myPath)) {
            myConfig = require myPath;
            static::write(myConfig);

            return static::read("Cake.version");
        }

        return "unknown";
    }

    /**
     * Used to write runtime configuration into Cache. Stored runtime configuration can be
     * restored using `Configure::restore()`. These methods can be used to enable configuration managers
     * frontends, or other GUI type interfaces for configuration.
     *
     * @param string myName The storage name for the saved configuration.
     * @param string cacheConfig The cache configuration to save into. Defaults to "default"
     * @param array|null myData Either an array of data to store, or leave empty to store all values.
     * @return bool Success
     * @throws \RuntimeException
     */
    static bool store(string myName, string cacheConfig = "default", ?array myData = null) {
        if (myData is null) {
            myData = static::$_values;
        }
        if (!class_exists(Cache::class)) {
            throw new RuntimeException("You must install UIM/cache to use Configure::store()");
        }

        return Cache::write(myName, myData, $cacheConfig);
    }

    /**
     * Restores configuration data stored in the Cache into configure. Restored
     * values will overwrite existing ones.
     *
     * @param string myName Name of the stored config file to load.
     * @param string cacheConfig Name of the Cache configuration to read from.
     * @return bool Success.
     * @throws \RuntimeException
     */
    static bool restore(string myName, string cacheConfig = "default") {
        if (!class_exists(Cache::class)) {
            throw new RuntimeException("You must install UIM/cache to use Configure::restore()");
        }
        myValues = Cache::read(myName, $cacheConfig);
        if (myValues) {
            static::write(myValues);

            return true;
        }

        return false;
    }

    // Clear all values stored in Configure.
    static void clear() {
        static::$_values = [];
    }
}
