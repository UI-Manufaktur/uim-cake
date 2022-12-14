/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.caches.cache;

@safe:
import uim.cake;

/**
 * Cache provides a consistent interface to Caching in your application. It allows you
 * to use several different Cache engines, without coupling your application to a specific
 * implementation. It also allows you to change out cache storage or configuration without effecting
 * the rest of your application.
 *
 * ### Configuring Cache engines
 *
 * You can configure Cache engines in your application"s `Config/cache.php` file.
 * A sample configuration would be:
 *
 * ```
 * Cache::config("shared", [
 *    "className":Cake\Cache\Engine\ApcuEngine::class,
 *    "prefix":"my_app_"
 * ]);
 * ```
 *
 * This would configure an APCu cache engine to the "shared" alias. You could then read and write
 * to that cache alias by using it for the `myConfig` parameter in the various Cache methods.
 *
 * In general all Cache operations are supported by all cache engines.
 * However, Cache::increment() and Cache::decrement() are not supported by File caching.
 *
 * There are 7 built-in caching engines:
 *
 * - `ApcuEngine` - Uses the APCu object cache, one of the fastest caching engines.
 * - `ArrayEngine` - Uses only memory to store all data, not actually a persistent engine.
 *    Can be useful in test or CLI environment.
 * - `FileEngine` - Uses simple files to store content. Poor performance, but good for
 *    storing large objects, or things that are not IO sensitive. Well suited to development
 *    as it is an easy cache to inspect and manually flush.
 * - `MemcacheEngine` - Uses the PECL::Memcache extension and Memcached for storage.
 *    Fast reads/writes, and benefits from memcache being distributed.
 * - `RedisEngine` - Uses redis and php-redis extension to store cache data.
 * - `WincacheEngine` - Uses Windows Cache Extension for PHP. Supports wincache 1.1.0 and higher.
 *    This engine is recommended to people deploying on windows with IIS.
 * - `XcacheEngine` - Uses the Xcache extension, an alternative to APCu.
 *
 * See Cache engine documentation for expected configuration keys.
 *
 * @see config/app.php for configuration settings
 */
class Cache {
    use StaticConfigTrait;

    // An array mapping URL schemes to fully qualified caching engine class names.
    protected static STRINGAA $_dsnClassMap = [
        "array":Engine\ArrayEngine::class,
        "apcu":Engine\ApcuEngine::class,
        "file":Engine\FileEngine::class,
        "memcached":Engine\MemcachedEngine::class,
        "null":Engine\NullEngine::class,
        "redis":Engine\RedisEngine::class,
        "wincache":Engine\WincacheEngine::class,
    ];

    // Flag for tracking whether caching is enabled.
    protected static bool $_enabled = true;

    // Group to Config mapping
    protected static array<string, array> $_groups = [];

    // Cache Registry used for creating and using cache adapters.
    protected static CacheRegistry $_registry;

    /**
     * Returns the Cache Registry instance used for creating and using cache adapters.
     *
     * @return \Cake\Cache\CacheRegistry
     */
    static CacheRegistry getRegistry() {
        if (static::$_registry == null) {
            static::$_registry = new CacheRegistry();
        }

        return static::$_registry;
    }

    /**
     * Sets the Cache Registry instance used for creating and using cache adapters.
     *
     * Also allows for injecting of a new registry instance.
     * @param \Cake\Cache\CacheRegistry $registry Injectable registry object.
     * 
     */
    static void setRegistry(CacheRegistry $registry) {
        static::$_registry = $registry;
    }

    /**
     * Finds and builds the instance of the required engine class.
     *
     * @param string myName Name of the config array that needs an engine instance built
     * @throws \Cake\Cache\InvalidArgumentException When a cache engine cannot be created.
     * @throws \RuntimeException If loading of the engine failed.
     */
    protected static void _buildEngine(string myName) {
        $registry = static::getRegistry();

        if (empty(static::$_config[myName]["className"])) {
            throw new InvalidArgumentException(
                sprintf("The "%s" cache configuration does not exist.", myName)
            );
        }

        /** @var array myConfig */
        myConfig = static::$_config[myName];

        try {
            $registry.load(myName, myConfig);
        } catch (RuntimeException $e) {
            if (!array_key_exists("fallback", myConfig)) {
                $registry.set(myName, new NullEngine());
                trigger_error($e.getMessage(), E_USER_WARNING);

                return;
            }

            if (myConfig["fallback"] == false) {
                throw $e;
            }

            if (myConfig["fallback"] == myName) {
                throw new InvalidArgumentException(sprintf(
                    ""%s" cache configuration cannot fallback to itself.",
                    myName
                ), 0, $e);
            }

            /** @var \Cake\Cache\CacheEngine $fallbackEngine */
            $fallbackEngine = clone static::pool(myConfig["fallback"]);
            $newConfig = myConfig + ["groups":[], "prefix":null];
            $fallbackEngine.setConfig("groups", $newConfig["groups"], false);
            if ($newConfig["prefix"]) {
                $fallbackEngine.setConfig("prefix", $newConfig["prefix"], false);
            }
            $registry.set(myName, $fallbackEngine);
        }

        if (myConfig["className"] instanceof CacheEngine) {
            myConfig = myConfig["className"].getConfig();
        }

        if (!empty(myConfig["groups"])) {
            foreach (myConfig["groups"] as myGroup) {
                static::$_groups[myGroup][] = myName;
                static::$_groups[myGroup] = array_unique(static::$_groups[myGroup]);
                sort(static::$_groups[myGroup]);
            }
        }
    }

    /**
     * Get a cache engine object for the named cache config.
     *
     * @param string myConfig The name of the configured cache backend.
     * @return \Psr\SimpleCache\ICache&\Cake\Cache\ICacheEngine
     * @deprecated 3.7.0 Use {@link pool()} instead. This method will be removed in 5.0.
     */
    static function engine(string myConfig) {
        deprecationWarning("Cache::engine() is deprecated. Use Cache::pool() instead.");

        return static::pool(myConfig);
    }

    /**
     * Get a SimpleCacheEngine object for the named cache pool.
     *
     * @param string myConfig The name of the configured cache backend.
     * @return \Psr\SimpleCache\ICache&\Cake\Cache\ICacheEngine
     */
    static function pool(string myConfig) {
        if (!static::$_enabled) {
            return new NullEngine();
        }

        $registry = static::getRegistry();

        if (isset($registry.{myConfig})) {
            return $registry.{myConfig};
        }

        static::_buildEngine(myConfig);

        return $registry.{myConfig};
    }

    /**
     * Write data for key into cache.
     *
     * ### Usage:
     *
     * Writing to the active cache config:
     *
     * ```
     * Cache::write("cached_data", myData);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::write("cached_data", myData, "long_term");
     * ```
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached - anything except a resource
     * @param string myConfig Optional string configuration name to write to. Defaults to "default"
     * @return bool True if the data was successfully cached, false on failure
     */
    static bool write(string myKey, myValue, string myConfig = "default") {
        if (is_resource(myValue)) {
            return false;
        }

        $backend = static::pool(myConfig);
        $success = $backend.set(myKey, myValue);
        if ($success == false && myValue !== "") {
            trigger_error(
                sprintf(
                    "%s cache was unable to write "%s" to %s cache",
                    myConfig,
                    myKey,
                    get_class($backend)
                ),
                E_USER_WARNING
            );
        }

        return $success;
    }

    /**
     *  Write data for many keys into cache.
     *
     * ### Usage:
     *
     * Writing to the active cache config:
     *
     * ```
     * Cache::writeMany(["cached_data_1":"data 1", "cached_data_2":"data 2"]);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::writeMany(["cached_data_1":"data 1", "cached_data_2":"data 2"], "long_term");
     * ```
     *
     * @param iterable myData An array or Traversable of data to be stored in the cache
     * @param string myConfig Optional string configuration name to write to. Defaults to "default"
     * @return bool True on success, false on failure
     * @throws \Cake\Cache\InvalidArgumentException
     */
    static bool writeMany(iterable myData, string myConfig = "default") {
        return static::pool(myConfig).setMultiple(myData);
    }

    /**
     * Read a key from the cache.
     *
     * ### Usage:
     *
     * Reading from the active cache configuration.
     *
     * ```
     * Cache::read("my_data");
     * ```
     *
     * Reading from a specific cache configuration.
     *
     * ```
     * Cache::read("my_data", "long_term");
     * ```
     *
     * @param string myKey Identifier for the data
     * @param string myConfig optional name of the configuration to use. Defaults to "default"
     * @return mixed The cached data, or null if the data doesn"t exist, has expired,
     *  or if there was an error fetching it.
     */
    static function read(string myKey, string myConfig = "default") {
        return static::pool(myConfig).get(myKey);
    }

    /**
     * Read multiple keys from the cache.
     *
     * ### Usage:
     *
     * Reading multiple keys from the active cache configuration.
     *
     * ```
     * Cache::readMany(["my_data_1", "my_data_2]);
     * ```
     *
     * Reading from a specific cache configuration.
     *
     * ```
     * Cache::readMany(["my_data_1", "my_data_2], "long_term");
     * ```
     *
     * @param iterable myKeys An array or Traversable of keys to fetch from the cache
     * @param string myConfig optional name of the configuration to use. Defaults to "default"
     * @return iterable An array containing, for each of the given myKeys,
     *   the cached data or false if cached data could not be retrieved.
     * @throws \Cake\Cache\InvalidArgumentException
     */
    static iterable readMany(iterable myKeys, string myConfig = "default") {
        return static::pool(myConfig).getMultiple(myKeys);
    }

    /**
     * Increment a number under the key and return incremented value.
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to add
     * @param string myConfig Optional string configuration name. Defaults to "default"
     * @return int|false New value, or false if the data doesn"t exist, is not integer,
     *    or if there was an error fetching it.
     * @throws \Cake\Cache\InvalidArgumentException When offset < 0
     */
    static function increment(string myKey, int $offset = 1, string myConfig = "default") {
        if ($offset < 0) {
            throw new InvalidArgumentException("Offset cannot be less than 0.");
        }

        return static::pool(myConfig).increment(myKey, $offset);
    }

    /**
     * Decrement a number under the key and return decremented value.
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @param string myConfig Optional string configuration name. Defaults to "default"
     * @return int|false New value, or false if the data doesn"t exist, is not integer,
     *   or if there was an error fetching it
     * @throws \Cake\Cache\InvalidArgumentException when offset < 0
     */
    static function decrement(string myKey, int $offset = 1, string myConfig = "default") {
        if ($offset < 0) {
            throw new InvalidArgumentException("Offset cannot be less than 0.");
        }

        return static::pool(myConfig).decrement(myKey, $offset);
    }

    /**
     * Delete a key from the cache.
     *
     * ### Usage:
     *
     * Deleting from the active cache configuration.
     *
     * ```
     * Cache::delete("my_data");
     * ```
     *
     * Deleting from a specific cache configuration.
     *
     * ```
     * Cache::delete("my_data", "long_term");
     * ```
     *
     * @param string myKey Identifier for the data
     * @param string myConfig name of the configuration to use. Defaults to "default"
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    static bool delete(string myKey, string myConfig = "default") {
        return static::pool(myConfig).delete(myKey);
    }

    /**
     * Delete many keys from the cache.
     *
     * ### Usage:
     *
     * Deleting multiple keys from the active cache configuration.
     *
     * ```
     * Cache::deleteMany(["my_data_1", "my_data_2"]);
     * ```
     *
     * Deleting from a specific cache configuration.
     *
     * ```
     * Cache::deleteMany(["my_data_1", "my_data_2], "long_term");
     * ```
     *
     * @param iterable myKeys Array or Traversable of cache keys to be deleted
     * @param string myConfig name of the configuration to use. Defaults to "default"
     * @return bool True on success, false on failure.
     * @throws \Cake\Cache\InvalidArgumentException
     */
    static bool deleteMany(iterable myKeys, string myConfig = "default") {
        return static::pool(myConfig).deleteMultiple(myKeys);
    }

    /**
     * Delete all keys from the cache.
     *
     * @param string myConfig name of the configuration to use. Defaults to "default"
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    static bool clear(string myConfig = "default") {
        return static::pool(myConfig).clear();
    }

    /**
     * Delete all keys from the cache from all configurations.
     * @return Status code. For each configuration, it reports the status of the operation
     */
    static function clearAll() {
        bool[string] results;

        foreach (self::configured() as myConfig) {
            results[myConfig] = self::clear(myConfig);
        }

        return results;
    }

    /**
     * Delete all keys from the cache belonging to the same group.
     *
     * @param string myGroup name of the group to be cleared
     * @param string myConfig name of the configuration to use. Defaults to "default"
     * @return bool True if the cache group was successfully cleared, false otherwise
     */
    static bool clearGroup(string myGroup, string myConfig = "default") {
        return static::pool(myConfig).clearGroup(myGroup);
    }

    /**
     * Retrieve group names to config mapping.
     *
     * ```
     * Cache::config("daily", ["duration":"1 day", "groups":["posts"]]);
     * Cache::config("weekly", ["duration":"1 week", "groups":["posts", "archive"]]);
     * myConfigs = Cache::groupConfigs("posts");
     * ```
     *
     * myConfigs will equal to `["posts":["daily", "weekly"]]`
     * Calling this method will load all the configured engines.
     *
     * @param string|null myGroup Group name or null to retrieve all group mappings
     * @return array<string, array> Map of group and all configuration that has the same group
     * @throws \Cake\Cache\InvalidArgumentException
     */
    static array groupConfigs(Nullable!string myGroup = null) {
        foreach (static::configured() as myConfig) {
            static::pool(myConfig);
        }
        if (myGroup == null) {
            return static::$_groups;
        }

        if (isset(self::$_groups[myGroup])) {
            return [myGroup: self::$_groups[myGroup]];
        }

        throw new InvalidArgumentException(sprintf("Invalid cache group %s", myGroup));
    }

    /**
     * Re-enable caching.
     * If caching has been disabled with Cache::disable() this method will reverse that effect.
     */
    static void enable() {
        static::$_enabled = true;
    }

    /**
     * Disable caching.
     *
     * When disabled all cache operations will return null.
     */
    static void disable() {
        static::$_enabled = false;
    }

    /**
     * Check whether caching is enabled.
     *
     * @return bool
     */
    static bool enabled() {
        return static::$_enabled;
    }

    /**
     * Provides the ability to easily do read-through caching.
     *
     * When called if the myKey is not set in myConfig, the $callable function
     * will be invoked. The results will then be stored into the cache config
     * at key.
     *
     * Examples:
     *
     * Using a Closure to provide data, assume `this` is a Table object:
     *
     * ```
     * myResults = Cache::remember("all_articles", function () {
     *      return this.find("all").toArray();
     * });
     * ```
     *
     * @param string myKey The cache key to read/store data at.
     * @param callable $callable The callable that provides data in the case when
     *   the cache key is empty. Can be any callable type supported by your PHP.
     * @param string myConfig The cache configuration to use for this operation.
     *   Defaults to default.
     * @return mixed If the key is found: the cached data.
     *   If the key is not found the value returned by the callable.
     */
    static function remember(string myKey, callable $callable, string myConfig = "default") {
        $existing = self::read(myKey, myConfig);
        if ($existing !== null) {
            return $existing;
        }
        myResults = $callable();
        self::write(myKey, myResults, myConfig);

        return myResults;
    }

    /**
     * Write data for key into a cache engine if it doesn"t exist already.
     *
     * ### Usage:
     *
     * Writing to the active cache config:
     *
     * ```
     * Cache::add("cached_data", myData);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::add("cached_data", myData, "long_term");
     * ```
     *
     * @param string myKey Identifier for the data.
     * @param mixed myValue Data to be cached - anything except a resource.
     * @param string myConfig Optional string configuration name to write to. Defaults to "default".
     * @return bool True if the data was successfully cached, false on failure.
     *   Or if the key existed already.
     */
    static bool add(string myKey, myValue, string myConfig = "default") {
        if (is_resource(myValue)) {
            return false;
        }

        return static::pool(myConfig).add(myKey, myValue);
    }
}
