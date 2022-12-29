


 *


 * @since         3.5.4
  */
module uim.cake.caches.Engine;

use APCUIterator;
import uim.cake.caches.CacheEngine;
use RuntimeException;

/**
 * APCu storage engine for cache
 */
class ApcuEngine : CacheEngine
{
    /**
     * Contains the compiled group names
     * (prefixed with the global configuration prefix)
     *
     * @var array<string>
     */
    protected string[] $_compiledGroupNames = [];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> $config array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array $config = []) {
        if (!extension_loaded("apcu")) {
            throw new RuntimeException("The `apcu` extension must be enabled to use ApcuEngine.");
        }

        return parent::init($config);
    }

    /**
     * Write data for key into cache
     *
     * @param string $key Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @link https://secure.php.net/manual/en/function.apcu-store.php
     */
    bool set($key, $value, $ttl = null) {
        $key = _key($key);
        $duration = this.duration($ttl);

        return apcu_store($key, $value, $duration);
    }

    /**
     * Read a key from the cache
     *
     * @param string $key Identifier for the data
     * @param mixed $default Default value in case the cache misses.
     * @return mixed The cached data, or default if the data doesn"t exist,
     *   has expired, or if there was an error fetching it
     * @link https://secure.php.net/manual/en/function.apcu-fetch.php
     */
    function get($key, $default = null) {
        $value = apcu_fetch(_key($key), $success);
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
     * @link https://secure.php.net/manual/en/function.apcu-inc.php
     */
    function increment(string $key, int $offset = 1) {
        $key = _key($key);

        return apcu_inc($key, $offset);
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     * @link https://secure.php.net/manual/en/function.apcu-dec.php
     */
    function decrement(string $key, int $offset = 1) {
        $key = _key($key);

        return apcu_dec($key, $offset);
    }

    /**
     * Delete a key from the cache
     *
     * @param string $key Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     * @link https://secure.php.net/manual/en/function.apcu-delete.php
     */
    bool delete($key) {
        $key = _key($key);

        return apcu_delete($key);
    }

    /**
     * Delete all keys from the cache. This will clear every cache config using APC.
     *
     * @return bool True Returns true.
     * @link https://secure.php.net/manual/en/function.apcu-cache-info.php
     * @link https://secure.php.net/manual/en/function.apcu-delete.php
     */
    bool clear() {
        if (class_exists(APCUIterator::class, false)) {
            $iterator = new APCUIterator(
                "/^" . preg_quote(_config["prefix"], "/") . "/",
                APC_ITER_NONE
            );
            apcu_delete($iterator);

            return true;
        }

        $cache = apcu_cache_info(); // Raises warning by itself already
        foreach ($cache["cache_list"] as $key) {
            if (strpos($key["info"], _config["prefix"]) == 0) {
                apcu_delete($key["info"]);
            }
        }

        return true;
    }

    /**
     * Write data for key into cache if it doesn"t exist already.
     * If it already exists, it fails and returns false.
     *
     * @param string $key Identifier for the data.
     * @param mixed $value Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     * @link https://secure.php.net/manual/en/function.apcu-add.php
     */
    bool add(string $key, $value) {
        $key = _key($key);
        $duration = _config["duration"];

        return apcu_add($key, $value, $duration);
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

        $success = false;
        $groups = apcu_fetch(_compiledGroupNames, $success);
        if ($success && count($groups) != count(_config["groups"])) {
            foreach (_compiledGroupNames as $group) {
                if (!isset($groups[$group])) {
                    $value = 1;
                    if (apcu_store($group, $value) == false) {
                        this.warning(
                            sprintf("Failed to store key "%s" with value "%s" into APCu cache.", $group, $value)
                        );
                    }
                    $groups[$group] = $value;
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
     * @link https://secure.php.net/manual/en/function.apcu-inc.php
     */
    bool clearGroup(string $group) {
        $success = false;
        apcu_inc(_config["prefix"] . $group, 1, $success);

        return $success;
    }
}
