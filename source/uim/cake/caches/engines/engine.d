module uim.cake.caches.engine;

@safe:
import uim.cake;

/**
 * Storage engine for UIM caching
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
    protected STRINGAA _defaultConfig = [
        "duration":3600,
        "groups":[],
        "prefix":"cake_",
        "warnOnWriteFailures":true,
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
     * @param array<string, mixed> myConfig Associative array of parameters for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
        this.setConfig(myConfig);

        if (!empty(this._config["groups"])) {
            sort(this._config["groups"]);
            this._groupPrefix = str_repeat("%s_", count(this._config["groups"]));
        }
        if (!is_numeric(this._config["duration"])) {
            this._config["duration"] = strtotime(this._config["duration"]) - time();
        }

        return true;
    }

    /**
     * Ensure the validity of the given cache key.
     *
     * @param string myKey Key to check.
     * @return void
     * @throws \Cake\Cache\InvalidArgumentException When the key is not valid.
     */
    protected void ensureValidKey(myKey) {
        if (!is_string(myKey) || strlen(myKey) === 0) {
            throw new InvalidArgumentException("A cache key must be a non-empty string.");
        }
    }

    /**
     * Ensure the validity of the argument type and cache keys.
     *
     * @param iterable $iterable The iterable to check.
     * @param string $check Whether to check keys or values.
     * @return void
     * @throws \Cake\Cache\InvalidArgumentException
     */
    protected void ensureValidType($iterable, string $check = self::CHECK_VALUE) {
        if (!is_iterable($iterable)) {
            throw new InvalidArgumentException(sprintf(
                "A cache %s must be either an array or a Traversable.",
                $check === self::CHECK_VALUE ? "key set" : "set"
            ));
        }

        foreach ($iterable as myKey: myValue) {
            if ($check === self::CHECK_VALUE) {
                this.ensureValidKey(myValue);
            } else {
                this.ensureValidKey(myKey);
            }
        }
    }

    /**
     * Obtains multiple cache items by their unique keys.
     *
     * @param iterable myKeys A list of keys that can obtained in a single operation.
     * @param mixed $default Default value to return for keys that do not exist.
     * @return iterable A list of key value pairs. Cache keys that do not exist or are stale will have $default as value.
     * @throws \Cake\Cache\InvalidArgumentException If myKeys is neither an array nor a Traversable,
     *   or if any of the myKeys are not a legal value.
     */
    auto getMultiple(myKeys, $default = null): iterable
    {
        this.ensureValidType(myKeys);

        myResults = [];
        foreach (myKeys as myKey) {
            myResults[myKey] = this.get(myKey, $default);
        }

        return myResults;
    }

    /**
     * Persists a set of key: value pairs in the cache, with an optional TTL.
     *
     * @param iterable myValues A list of key: value pairs for a multiple-set operation.
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @throws \Cake\Cache\InvalidArgumentException If myValues is neither an array nor a Traversable,
     *   or if any of the myValues are not a legal value.
     */
    bool setMultiple(myValues, $ttl = null) {
        this.ensureValidType(myValues, self::CHECK_KEY);

        if ($ttl !== null) {
            $restore = this.getConfig("duration");
            this.setConfig("duration", $ttl);
        }
        try {
            foreach (myValues as myKey: myValue) {
                $success = this.set(myKey, myValue);
                if ($success === false) {
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
     * Deletes multiple cache items in a single operation.
     *
     * @param iterable myKeys A list of string-based keys to be deleted.
     * @return bool True if the items were successfully removed. False if there was an error.
     * @throws \Cake\Cache\InvalidArgumentException If myKeys is neither an array nor a Traversable,
     *   or if any of the myKeys are not a legal value.
     */
    bool deleteMultiple(myKeys) {
        this.ensureValidType(myKeys);

        foreach (myKeys as myKey) {
            myResult = this.delete(myKey);
            if (myResult === false) {
                return false;
            }
        }

        return true;
    }

    /**
     * Determines whether an item is present in the cache.
     *
     * NOTE: It is recommended that has() is only to be used for cache warming type purposes
     * and not to be used within your live applications operations for get/set, as this method
     * is subject to a race condition where your has() will return true and immediately after,
     * another script can remove it making the state of your app out of date.
     *
     * @param string myKey The cache item key.
     * @return bool
     * @throws \Cake\Cache\InvalidArgumentException If the myKey string is not a legal value.
     */
    bool has(myKey) {
        return this.get(myKey) !== null;
    }

    /**
     * Fetches the value for a given key from the cache.
     *
     * @param string myKey The unique key of this item in the cache.
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The value of the item from the cache, or $default in case of cache miss.
     * @throws \Cake\Cache\InvalidArgumentException If the myKey string is not a legal value.
     */
    abstract auto get(myKey, $default = null);

    /**
     * Persists data in the cache, uniquely referenced by the given key with an optional expiration TTL time.
     *
     * @param string myKey The key of the item to store.
     * @param mixed myValue The value of the item to store, must be serializable.
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @throws \Cake\Cache\InvalidArgumentException
     *   MUST be thrown if the myKey string is not a legal value.
     */
    abstract bool set(myKey, myValue, $ttl = null);

    /**
     * Increment a number under the key and return incremented value
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to add
     * @return int|false New incremented value, false otherwise
     */
    abstract function increment(string myKey, int $offset = 1);

    /**
     * Decrement a number under the key and return decremented value
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New incremented value, false otherwise
     */
    abstract function decrement(string myKey, int $offset = 1);

    /**
     * Delete a key from the cache
     *
     * @param string myKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    abstract bool delete(myKey);

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
     * @param string myKey Identifier for the data.
     * @param mixed myValue Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     */
    bool add(string myKey, myValue) {
        $cachedValue = this.get(myKey);
        if ($cachedValue === null) {
            return this.set(myKey, myValue);
        }

        return false;
    }

    /**
     * Clears all values belonging to a group. Is up to the implementing engine
     * to decide whether actually delete the keys or just simulate it to achieve
     * the same result.
     *
     * @param string myGroup name of the group to be cleared
     * @return bool
     */
    abstract bool clearGroup(string myGroup);

    /**
     * Does whatever initialization for each group is required
     * and returns the `group value` for each of them, this is
     * the token representing each group in the cache key
     *
     * @return array<string>
     */
    function groups(): array
    {
        return this._config["groups"];
    }

    /**
     * Generates a key for cache backend usage.
     *
     * If the requested key is valid, the group prefix value and engine prefix are applied.
     * Whitespace in keys will be replaced.
     *
     * @param string myKey the key passed over
     * @return string Prefixed key with potentially unsafe characters replaced.
     * @throws \Cake\Cache\InvalidArgumentException If key"s value is invalid.
     */
    protected string _key(myKey) {
        this.ensureValidKey(myKey);

        $prefix = "";
        if (this._groupPrefix) {
            $prefix = md5(implode("_", this.groups()));
        }
        myKey = preg_replace("/[\s]+/", "_", myKey);

        return this._config["prefix"] . $prefix . myKey;
    }

    /**
     * Cache Engines may trigger warnings if they encounter failures during operation,
     * if option warnOnWriteFailures is set to true.
     *
     * @param string myMessage The warning message.
     */
    protected void warning(string myMessage) {
        if (this.getConfig("warnOnWriteFailures") !== true) {
            return;
        }

        triggerWarning(myMessage);
    }

    /**
     * Convert the various expressions of a TTL value into duration in seconds
     *
     * @param \DateInterval|int|null $ttl The TTL value of this item. If null is sent, the
     *   driver"s default duration will be used.
     * @return int
     */
    protected int duration($ttl) {
        if ($ttl === null) {
            return this._config["duration"];
        }
        if (is_int($ttl)) {
            return $ttl;
        }
        if ($ttl instanceof DateInterval) {
            return (int)$ttl.format("%s");
        }

        throw new InvalidArgumentException("TTL values must be one of null, int, \DateInterval");
    }
}
