module uim.cake.caches;

import uim.cake.caches.engines.NullEngine;
import uim.cake.core.StaticConfigTrait;
use RuntimeException;

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
 *    "className": Cake\Cache\Engine\ApcuEngine::class,
 *    "prefix": "my_app_"
 * ]);
 * ```
 *
 * This would configure an APCu cache engine to the "shared" alias. You could then read and write
 * to that cache alias by using it for the `$config` parameter in the various Cache methods.
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

    /**
     * An array mapping URL schemes to fully qualified caching engine
     * class names.
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string>
     */
    protected static $_dsnClassMap = [
        "array": Engine\ArrayEngine::class,
        "apcu": Engine\ApcuEngine::class,
        "file": Engine\FileEngine::class,
        "memcached": Engine\MemcachedEngine::class,
        "null": Engine\NullEngine::class,
        "redis": Engine\RedisEngine::class,
        "wincache": Engine\WincacheEngine::class,
    ];

    /**
     * Flag for tracking whether caching is enabled.
     *
     */
    protected static bool $_enabled = true;

    /**
     * Group to Config mapping
     *
     * @var array<string, array>
     */
    protected static $_groups = [];

    /**
     * Cache Registry used for creating and using cache adapters.
     *
     * @var uim.cake.Cache\CacheRegistry|null
     */
    protected static $_registry;

    /**
     * Returns the Cache Registry instance used for creating and using cache adapters.
     *
     * @return uim.cake.Cache\CacheRegistry
     */
    static function getRegistry(): CacheRegistry
    {
        if (static::$_registry == null) {
            static::$_registry = new CacheRegistry();
        }

        return static::$_registry;
    }

    /**
     * Sets the Cache Registry instance used for creating and using cache adapters.
     *
     * Also allows for injecting of a new registry instance.
     *
     * @param uim.cake.Cache\CacheRegistry $registry Injectable registry object.
     */
    static void setRegistry(CacheRegistry $registry) {
        static::$_registry = $registry;
    }

    /**
     * Finds and builds the instance of the required engine class.
     *
     * @param string aName Name of the config array that needs an engine instance built
     * @throws uim.cake.Cache\InvalidArgumentException When a cache engine cannot be created.
     * @throws \RuntimeException If loading of the engine failed.
     * @return void
     */
    protected static void _buildEngine(string aName) {
        $registry = static::getRegistry();

        if (empty(static::$_config[$name]["className"])) {
            throw new InvalidArgumentException(
                sprintf("The "%s" cache configuration does not exist.", $name)
            );
        }

        /** @var array $config */
        $config = static::$_config[$name];

        try {
            $registry.load($name, $config);
        } catch (RuntimeException $e) {
            if (!array_key_exists("fallback", $config)) {
                $registry.set($name, new NullEngine());
                trigger_error($e.getMessage(), E_USER_WARNING);

                return;
            }

            if ($config["fallback"] == false) {
                throw $e;
            }

            if ($config["fallback"] == $name) {
                throw new InvalidArgumentException(sprintf(
                    ""%s" cache configuration cannot fallback to itself.",
                    $name
                ), 0, $e);
            }

            /** @var uim.cake.Cache\CacheEngine $fallbackEngine */
            $fallbackEngine = clone static::pool($config["fallback"]);
            $newConfig = $config + ["groups": [], "prefix": null];
            $fallbackEngine.setConfig("groups", $newConfig["groups"], false);
            if ($newConfig["prefix"]) {
                $fallbackEngine.setConfig("prefix", $newConfig["prefix"], false);
            }
            $registry.set($name, $fallbackEngine);
        }

        if ($config["className"] instanceof CacheEngine) {
            $config = $config["className"].getConfig();
        }

        if (!empty($config["groups"])) {
            foreach ($config["groups"] as $group) {
                static::$_groups[$group][] = $name;
                static::$_groups[$group] = array_unique(static::$_groups[$group]);
                sort(static::$_groups[$group]);
            }
        }
    }

    /**
     * Get a cache engine object for the named cache config.
     *
     * @param string $config The name of the configured cache backend.
     * @return \Psr\SimpleCache\ICache&uim.cake.Cache\ICacheEngine
     * @deprecated 3.7.0 Use {@link pool()} instead. This method will be removed in 5.0.
     */
    static function engine(string $config) {
        deprecationWarning("Cache::engine() is deprecated. Use Cache::pool() instead.");

        return static::pool($config);
    }

    /**
     * Get a SimpleCacheEngine object for the named cache pool.
     *
     * @param string $config The name of the configured cache backend.
     * @return \Psr\SimpleCache\ICache &uim.cake.Cache\ICacheEngine
     */
    static function pool(string $config) {
        if (!static::$_enabled) {
            return new NullEngine();
        }

        $registry = static::getRegistry();

        if (isset($registry.{$config})) {
            return $registry.{$config};
        }

        static::_buildEngine($config);

        return $registry.{$config};
    }

    /**
     * Write data for key into cache.
     *
     * ### Usage:
     *
     * Writing to the active cache config:
     *
     * ```
     * Cache::write("cached_data", $data);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::write("cached_data", $data, "long_term");
     * ```
     *
     * @param string aKey Identifier for the data
     * @param mixed $value Data to be cached - anything except a resource
     * @param string $config Optional string configuration name to write to. Defaults to "default"
     * @return bool True if the data was successfully cached, false on failure
     */
    static bool write(string aKey, $value, string $config = "default") {
        if (is_resource($value)) {
            return false;
        }

        $backend = static::pool($config);
        $success = $backend.set($key, $value);
        if ($success == false && $value != "") {
            trigger_error(
                sprintf(
                    "%s cache was unable to write "%s" to %s cache",
                    $config,
                    $key,
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
     * Cache::writeMany(["cached_data_1": "data 1", "cached_data_2": "data 2"]);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::writeMany(["cached_data_1": "data 1", "cached_data_2": "data 2"], "long_term");
     * ```
     *
     * @param iterable $data An array or Traversable of data to be stored in the cache
     * @param string $config Optional string configuration name to write to. Defaults to "default"
     * @return bool True on success, false on failure
     * @throws uim.cake.Cache\InvalidArgumentException
     */
    static bool writeMany(iterable $data, string $config = "default") {
        return static::pool($config).setMultiple($data);
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
     * @param string aKey Identifier for the data
     * @param string $config optional name of the configuration to use. Defaults to "default"
     * @return mixed The cached data, or null if the data doesn"t exist, has expired,
     *  or if there was an error fetching it.
     */
    static function read(string aKey, string $config = "default") {
        return static::pool($config).get($key);
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
     * @param iterable $keys An array or Traversable of keys to fetch from the cache
     * @param string $config optional name of the configuration to use. Defaults to "default"
     * @return iterable An array containing, for each of the given $keys,
     *   the cached data or false if cached data could not be retrieved.
     * @throws uim.cake.Cache\InvalidArgumentException
     */
    static function readMany(iterable $keys, string $config = "default"): iterable
    {
        return static::pool($config).getMultiple($keys);
    }

    /**
     * Increment a number under the key and return incremented value.
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to add
     * @param string $config Optional string configuration name. Defaults to "default"
     * @return int|false New value, or false if the data doesn"t exist, is not integer,
     *    or if there was an error fetching it.
     * @throws uim.cake.Cache\InvalidArgumentException When offset < 0
     */
    static function increment(string aKey, int $offset = 1, string $config = "default") {
        if ($offset < 0) {
            throw new InvalidArgumentException("Offset cannot be less than 0.");
        }

        return static::pool($config).increment($key, $offset);
    }

    /**
     * Decrement a number under the key and return decremented value.
     *
     * @param string aKey Identifier for the data
     * @param int $offset How much to subtract
     * @param string $config Optional string configuration name. Defaults to "default"
     * @return int|false New value, or false if the data doesn"t exist, is not integer,
     *   or if there was an error fetching it
     * @throws uim.cake.Cache\InvalidArgumentException when offset < 0
     */
    static function decrement(string aKey, int $offset = 1, string $config = "default") {
        if ($offset < 0) {
            throw new InvalidArgumentException("Offset cannot be less than 0.");
        }

        return static::pool($config).decrement($key, $offset);
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
     * @param string aKey Identifier for the data
     * @param string $config name of the configuration to use. Defaults to "default"
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    static bool delete(string aKey, string $config = "default") {
        return static::pool($config).delete($key);
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
     * @param iterable $keys Array or Traversable of cache keys to be deleted
     * @param string $config name of the configuration to use. Defaults to "default"
     * @return bool True on success, false on failure.
     * @throws uim.cake.Cache\InvalidArgumentException
     */
    static bool deleteMany(iterable $keys, string $config = "default") {
        return static::pool($config).deleteMultiple($keys);
    }

    /**
     * Delete all keys from the cache.
     *
     * @param string $config name of the configuration to use. Defaults to "default"
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    static bool clear(string $config = "default") {
        return static::pool($config).clear();
    }

    /**
     * Delete all keys from the cache from all configurations.
     *
     * @return array<string, bool> Status code. For each configuration, it reports the status of the operation
     */
    static function clearAll(): array
    {
        $status = [];

        foreach (self::configured() as $config) {
            $status[$config] = self::clear($config);
        }

        return $status;
    }

    /**
     * Delete all keys from the cache belonging to the same group.
     *
     * @param string $group name of the group to be cleared
     * @param string $config name of the configuration to use. Defaults to "default"
     * @return bool True if the cache group was successfully cleared, false otherwise
     */
    static function clearGroup(string $group, string $config = "default"): bool
    {
        return static::pool($config).clearGroup($group);
    }

    /**
     * Retrieve group names to config mapping.
     *
     * ```
     * Cache::config("daily", ["duration": "1 day", "groups": ["posts"]]);
     * Cache::config("weekly", ["duration": "1 week", "groups": ["posts", "archive"]]);
     * $configs = Cache::groupConfigs("posts");
     * ```
     *
     * $configs will equal to `["posts": ["daily", "weekly"]]`
     * Calling this method will load all the configured engines.
     *
     * @param string|null $group Group name or null to retrieve all group mappings
     * @return array<string, array> Map of group and all configuration that has the same group
     * @throws uim.cake.Cache\InvalidArgumentException
     */
    static function groupConfigs(?string $group = null): array
    {
        foreach (static::configured() as $config) {
            static::pool($config);
        }
        if ($group == null) {
            return static::$_groups;
        }

        if (isset(self::$_groups[$group])) {
            return [$group: self::$_groups[$group]];
        }

        throw new InvalidArgumentException(sprintf("Invalid cache group %s", $group));
    }

    /**
     * Re-enable caching.
     *
     * If caching has been disabled with Cache::disable() this method will reverse that effect.
     *
     */
    static void enable() {
        static::$_enabled = true;
    }

    /**
     * Disable caching.
     *
     * When disabled all cache operations will return null.
     *
     */
    static void disable() {
        static::$_enabled = false;
    }

    /**
     * Check whether caching is enabled.
     *
     * @return bool
     */
    static function enabled(): bool
    {
        return static::$_enabled;
    }

    /**
     * Provides the ability to easily do read-through caching.
     *
     * When called if the $key is not set in $config, the $callable function
     * will be invoked. The results will then be stored into the cache config
     * at key.
     *
     * Examples:
     *
     * Using a Closure to provide data, assume `this` is a Table object:
     *
     * ```
     * $results = Cache::remember("all_articles", function () {
     *      return this.find("all").toArray();
     * });
     * ```
     *
     * @param string aKey The cache key to read/store data at.
     * @param callable $callable The callable that provides data in the case when
     *   the cache key is empty. Can be any callable type supported by your PHP.
     * @param string $config The cache configuration to use for this operation.
     *   Defaults to default.
     * @return mixed If the key is found: the cached data.
     *   If the key is not found the value returned by the callable.
     */
    static function remember(string aKey, callable $callable, string $config = "default") {
        $existing = self::read($key, $config);
        if ($existing != null) {
            return $existing;
        }
        $results = $callable();
        self::write($key, $results, $config);

        return $results;
    }

    /**
     * Write data for key into a cache engine if it doesn"t exist already.
     *
     * ### Usage:
     *
     * Writing to the active cache config:
     *
     * ```
     * Cache::add("cached_data", $data);
     * ```
     *
     * Writing to a specific cache config:
     *
     * ```
     * Cache::add("cached_data", $data, "long_term");
     * ```
     *
     * @param string aKey Identifier for the data.
     * @param mixed $value Data to be cached - anything except a resource.
     * @param string $config Optional string configuration name to write to. Defaults to "default".
     * @return bool True if the data was successfully cached, false on failure.
     *   Or if the key existed already.
     */
    static function add(string aKey, $value, string $config = "default"): bool
    {
        if (is_resource($value)) {
            return false;
        }

        return static::pool($config).add($key, $value);
    }
}
