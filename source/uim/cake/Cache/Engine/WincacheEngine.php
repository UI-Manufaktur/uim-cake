


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.caches.Engine;

import uim.cake.caches.CacheEngine;
use RuntimeException;

/**
 * Wincache storage engine for cache
 *
 * Supports wincache 1.1.0 and higher.
 */
class WincacheEngine : CacheEngine
{
    /**
     * Contains the compiled group names
     * (prefixed with the global configuration prefix)
     *
     * @var array<string>
     */
    protected $_compiledGroupNames = [];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> $config array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array $config = []) {
        if (!extension_loaded("wincache")) {
            throw new RuntimeException("The `wincache` extension must be enabled to use WincacheEngine.");
        }

        parent::init($config);

        return true;
    }

    /**
     * Write data for key into cache
     *
     * @param string $key Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True if the data was successfully cached, false on failure
     */
    bool set($key, $value, $ttl = null) {
        $key = _key($key);
        $duration = this.duration($ttl);

        return wincache_ucache_set($key, $value, $duration);
    }

    /**
     * Read a key from the cache
     *
     * @param string $key Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist,
     *   has expired, or if there was an error fetching it
     */
    function get($key, $default = null) {
        $value = wincache_ucache_get(_key($key), $success);
        if ($success == false) {
            return $default;
        }

        return $value;
    }

    /**
     * Increments the value of an integer cached key
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string $key, int $offset = 1) {
        $key = _key($key);

        return wincache_ucache_inc($key, $offset);
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string $key, int $offset = 1) {
        $key = _key($key);

        return wincache_ucache_dec($key, $offset);
    }

    /**
     * Delete a key from the cache
     *
     * @param string $key Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool delete($key) {
        $key = _key($key);

        return wincache_ucache_delete($key);
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
        foreach ($cacheKeys as $key) {
            if (strpos($key["key_name"], _config["prefix"]) == 0) {
                wincache_ucache_delete($key["key_name"]);
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
            foreach (_config["groups"] as $group) {
                _compiledGroupNames[] = _config["prefix"] . $group;
            }
        }

        $groups = wincache_ucache_get(_compiledGroupNames);
        if (count($groups) != count(_config["groups"])) {
            foreach (_compiledGroupNames as $group) {
                if (!isset($groups[$group])) {
                    wincache_ucache_set($group, 1);
                    $groups[$group] = 1;
                }
            }
            ksort($groups);
        }

        $result = [];
        $groups = array_values($groups);
        foreach (_config["groups"] as $i: $group) {
            $result[] = $group . $groups[$i];
        }

        return $result;
    }

    /**
     * Increments the group value to simulate deletion of all keys under a group
     * old values will remain in storage until they expire.
     *
     * @param string $group The group to clear.
     * @return bool success
     */
    bool clearGroup(string $group) {
        $success = false;
        wincache_ucache_inc(_config["prefix"] . $group, 1, $success);

        return $success;
    }
}
