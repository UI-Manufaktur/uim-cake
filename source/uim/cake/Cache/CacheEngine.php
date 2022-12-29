


 *


 * @since         1.2.0
  */
module uim.cake.Cache;

import uim.cake.core.InstanceConfigTrait;
use DateInterval;
use DateTime;
use Psr\SimpleCache\ICache;

/**
 * Storage engine for CakePHP caching
 */
abstract class CacheEngine : ICache, ICacheEngine
{
    use InstanceConfigTrait;

    /**
     * @var string
     */
    protected const CHECK_KEY = "key";

    /**
     * @var string
     */
    protected const CHECK_VALUE = "value";

    /**
     * The default cache configuration is overridden in most cache adapters. These are
     * the keys that are common to all adapters. If overridden, this property is not used.
     *
     * - `duration` Specify how long items in this cache configuration last.
     * - `groups` List of groups or "tags" associated to every key stored in this config.
     *    handy for deleting a complete group from cache.
     * - `prefix` Prefix appended to all entries. Good for when you need to share a keyspace
     *    with either another cache config or another application.
     * - `warnOnWriteFailures` Some engines, such as ApcuEngine, may raise warnings on
     *    write failures.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "duration": 3600,
        "groups": [],
        "prefix": "cake_",
        "warnOnWriteFailures": true,
    ];

    /**
     * Contains the compiled string with all group
     * prefixes to be prepended to every key in this cache engine
     *
     * @var string
     */
    protected $_groupPrefix = "";

    /**
     * Initialize the cache engine
     *
     * Called automatically by the cache frontend. Merge the runtime config with the defaults
     * before use.
     *
     * @param array<string, mixed> $config Associative array of parameters for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array $config = []) {
        this.setConfig($config);

        if (!empty(_config["groups"])) {
            sort(_config["groups"]);
            _groupPrefix = str_repeat("%s_", count(_config["groups"]));
        }
        if (!is_numeric(_config["duration"])) {
            _config["duration"] = strtotime(_config["duration"]) - time();
        }

        return true;
    }

    /**
     * Ensure the validity of the given cache key.
     *
     * @param string $key Key to check.
     * @return void
     * @throws uim.cake.Cache\InvalidArgumentException When the key is not valid.
     */
    protected function ensureValidKey($key): void
    {
        if (!is_string($key) || strlen($key) == 0) {
            throw new InvalidArgumentException("A cache key must be a non-empty string.");
        }
    }

    /**
     * Ensure the validity of the argument type and cache keys.
     *
     * @param iterable $iterable The iterable to check.
     * @param string $check Whether to check keys or values.
     * @return void
     * @throws uim.cake.Cache\InvalidArgumentException
     */
    protected function ensureValidType($iterable, string $check = self::CHECK_VALUE): void
    {
        if (!is_iterable($iterable)) {
            throw new InvalidArgumentException(sprintf(
                "A cache %s must be either an array or a Traversable.",
                $check == self::CHECK_VALUE ? "key set" : "set"
            ));
        }

        foreach ($iterable as $key: $value) {
            if ($check == self::CHECK_VALUE) {
                this.ensureValidKey($value);
            } else {
                this.ensureValidKey($key);
            }
        }
    }

    /**
     * Obtains multiple cache items by their unique keys.
     *
     * @param iterable $keys A list of keys that can obtained in a single operation.
     * @param mixed $default Default value to return for keys that do not exist.
     * @return iterable A list of key value pairs. Cache keys that do not exist or are stale will have $default as value.
     * @throws uim.cake.Cache\InvalidArgumentException If $keys is neither an array nor a Traversable,
     *   or if any of the $keys are not a legal value.
     */
    function getMultiple($keys, $default = null): iterable
    {
        this.ensureValidType($keys);

        $results = [];
        foreach ($keys as $key) {
            $results[$key] = this.get($key, $default);
        }

        return $results;
    }

    /**
     * Persists a set of key: value pairs in the cache, with an optional TTL.
     *
     * @param iterable $values A list of key: value pairs for a multiple-set operation.
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @throws uim.cake.Cache\InvalidArgumentException If $values is neither an array nor a Traversable,
     *   or if any of the $values are not a legal value.
     */
    bool setMultiple($values, $ttl = null) {
        this.ensureValidType($values, self::CHECK_KEY);

        if ($ttl != null) {
            $restore = this.getConfig("duration");
            this.setConfig("duration", $ttl);
        }
        try {
            foreach ($values as $key: $value) {
                $success = this.set($key, $value);
                if ($success == false) {
                    return false;
                }
            }

            return true;
        } finally {
            if (isset($restore)) {
                this.setConfig("duration", $restore);
            }
        }
    }

    /**
     * Deletes multiple cache items as a list
     *
     * This is a best effort attempt. If deleting an item would
     * create an error it will be ignored, and all items will
     * be attempted.
     *
     * @param iterable $keys A list of string-based keys to be deleted.
     * @return bool True if the items were successfully removed. False if there was an error.
     * @throws uim.cake.Cache\InvalidArgumentException If $keys is neither an array nor a Traversable,
     *   or if any of the $keys are not a legal value.
     */
    bool deleteMultiple($keys) {
        this.ensureValidType($keys);

        $result = true;
        foreach ($keys as $key) {
            if (!this.delete($key)) {
                $result = false;
            }
        }

        return $result;
    }

    /**
     * Determines whether an item is present in the cache.
     *
     * NOTE: It is recommended that has() is only to be used for cache warming type purposes
     * and not to be used within your live applications operations for get/set, as this method
     * is subject to a race condition where your has() will return true and immediately after,
     * another script can remove it making the state of your app out of date.
     *
     * @param string $key The cache item key.
     * @return bool
     * @throws uim.cake.Cache\InvalidArgumentException If the $key string is not a legal value.
     */
    bool has($key) {
        return this.get($key) != null;
    }

    /**
     * Fetches the value for a given key from the cache.
     *
     * @param string $key The unique key of this item in the cache.
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The value of the item from the cache, or $default in case of cache miss.
     * @throws uim.cake.Cache\InvalidArgumentException If the $key string is not a legal value.
     */
    abstract function get($key, $default = null);

    /**
     * Persists data in the cache, uniquely referenced by the given key with an optional expiration TTL time.
     *
     * @param string $key The key of the item to store.
     * @param mixed $value The value of the item to store, must be serializable.
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @throws uim.cake.Cache\InvalidArgumentException
     *   MUST be thrown if the $key string is not a legal value.
     */
    abstract bool set($key, $value, $ttl = null);

    /**
     * Increment a number under the key and return incremented value
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to add
     * @return int|false New incremented value, false otherwise
     */
    abstract function increment(string $key, int $offset = 1);

    /**
     * Decrement a number under the key and return decremented value
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New incremented value, false otherwise
     */
    abstract function decrement(string $key, int $offset = 1);

    /**
     * Delete a key from the cache
     *
     * @param string $key Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    abstract bool delete($key);

    /**
     * Delete all keys from the cache
     *
     * @return bool True if the cache was successfully cleared, false otherwise
     */
    abstract bool clear();

    /**
     * Add a key to the cache if it does not already exist.
     *
     * Defaults to a non-atomic implementation. Subclasses should
     * prefer atomic implementations.
     *
     * @param string $key Identifier for the data.
     * @param mixed $value Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     */
    bool add(string $key, $value) {
        $cachedValue = this.get($key);
        if ($cachedValue == null) {
            return this.set($key, $value);
        }

        return false;
    }

    /**
     * Clears all values belonging to a group. Is up to the implementing engine
     * to decide whether actually delete the keys or just simulate it to achieve
     * the same result.
     *
     * @param string $group name of the group to be cleared
     * @return bool
     */
    abstract bool clearGroup(string $group);

    /**
     * Does whatever initialization for each group is required
     * and returns the `group value` for each of them, this is
     * the token representing each group in the cache key
     */
    string[] groups(): array
    {
        return _config["groups"];
    }

    /**
     * Generates a key for cache backend usage.
     *
     * If the requested key is valid, the group prefix value and engine prefix are applied.
     * Whitespace in keys will be replaced.
     *
     * @param string $key the key passed over
     * @return string Prefixed key with potentially unsafe characters replaced.
     * @throws uim.cake.Cache\InvalidArgumentException If key"s value is invalid.
     */
    protected function _key($key): string
    {
        this.ensureValidKey($key);

        $prefix = "";
        if (_groupPrefix) {
            $prefix = md5(implode("_", this.groups()));
        }
        $key = preg_replace("/[\s]+/", "_", $key);

        return _config["prefix"] . $prefix . $key;
    }

    /**
     * Cache Engines may trigger warnings if they encounter failures during operation,
     * if option warnOnWriteFailures is set to true.
     *
     * @param string $message The warning message.
     * @return void
     */
    protected function warning(string $message): void
    {
        if (this.getConfig("warnOnWriteFailures") != true) {
            return;
        }

        triggerWarning($message);
    }

    /**
     * Convert the various expressions of a TTL value into duration in seconds
     *
     * @param \DateInterval|int|null $ttl The TTL value of this item. If null is sent, the
     *   driver"s default duration will be used.
     * @return int
     */
    protected function duration($ttl): int
    {
        if ($ttl == null) {
            return _config["duration"];
        }
        if (is_int($ttl)) {
            return $ttl;
        }
        if ($ttl instanceof DateInterval) {
            return (int)DateTime::createFromFormat("U", "0")
                .add($ttl)
                .format("U");
        }

        throw new InvalidArgumentException("TTL values must be one of null, int, \DateInterval");
    }
}
