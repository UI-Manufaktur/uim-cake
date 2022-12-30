module uim.cake.caches.engines.wincache;

@safe:
import uim.cake;

/**
 * Wincache storage engine for cache
 *
 * Supports wincache 1.1.0 and higher.
 */
class WincacheEngine : CacheEngine {
    /**
     * Contains the compiled group names
     * (prefixed with the global configuration prefix)
     */
    protected string[] _compiledGroupNames = [];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> myConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
        if (!extension_loaded("wincache")) {
            throw new RuntimeException("The `wincache` extension must be enabled to use WincacheEngine.");
        }

        super.init(myConfig);

        return true;
    }

    /**
     * Write data for key into cache
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True if the data was successfully cached, false on failure
     */
    bool set(myKey, myValue, $ttl = null) {
        myKey = _key(myKey);
        $duration = this.duration($ttl);

        return wincache_ucache_set(myKey, myValue, $duration);
    }

    /**
     * Read a key from the cache
     *
     * @param string myKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist,
     *   has expired, or if there was an error fetching it
     */
    auto get(myKey, $default = null) {
        myValue = wincache_ucache_get(_key(myKey), $success);
        if ($success == false) {
            return $default;
        }

        return myValue;
    }

    /**
     * Increments the value of an integer cached key
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string myKey, int $offset = 1) {
        myKey = _key(myKey);

        return wincache_ucache_inc(myKey, $offset);
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string myKey, int $offset = 1) {
        myKey = _key(myKey);

        return wincache_ucache_dec(myKey, $offset);
    }

    /**
     * Delete a key from the cache
     *
     * @param string myKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool delete(myKey) {
        myKey = _key(myKey);

        return wincache_ucache_delete(myKey);
    }

    /**
     * Delete all keys from the cache. This will clear every
     * item in the cache matching the cache config prefix.
     *
     * @return bool True Returns true.
     */
    bool clear() {
        $info = wincache_ucache_info();
        $cacheKeys = $info["ucache_entries"];
        unset($info);
        foreach ($cacheKeys as myKey) {
            if (indexOf(myKey["key_name"], _config["prefix"]) == 0) {
                wincache_ucache_delete(myKey["key_name"]);
            }
        }

        return true;
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     */
    string[] groups() {
        if (empty(_compiledGroupNames)) {
            foreach (_config["groups"] as myGroup) {
                _compiledGroupNames[] = _config["prefix"] . myGroup;
            }
        }

        myGroups = wincache_ucache_get(_compiledGroupNames);
        if (count(myGroups) != count(_config["groups"])) {
            foreach (_compiledGroupNames as myGroup) {
                if (!isset(myGroups[myGroup])) {
                    wincache_ucache_set(myGroup, 1);
                    myGroups[myGroup] = 1;
                }
            }
            ksort(myGroups);
        }

        myResult = [];
        myGroups = array_values(myGroups);
        foreach (_config["groups"] as $i: myGroup) {
            myResult[] = myGroup . myGroups[$i];
        }

        return myResult;
    }

    /**
     * Increments the group value to simulate deletion of all keys under a group
     * old values will remain in storage until they expire.
     *
     * @param string myGroup The group to clear.
     * @return bool success
     */
    bool clearGroup(string myGroup) {
        $success = false;
        wincache_ucache_inc(_config["prefix"] . myGroup, 1, $success);

        return $success;
    }
}
