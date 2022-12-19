module uim.cake.caches.engines.apcu;

@safe:
import uim.cake

<!-- use APCUIterator;
import uim.cake.caches\CacheEngine;
use RuntimeException;
 -->
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
    protected _compiledGroupNames = [];

    /**
     * Initialize the Cache Engine
     *
     * Called automatically by the cache frontend
     *
     * @param array<string, mixed> myConfig array of setting for the engine
     * @return bool True if the engine has been successfully initialized, false if not
     */
    bool init(array myConfig = []) {
        if (!extension_loaded("apcu")) {
            throw new RuntimeException("The `apcu` extension must be enabled to use ApcuEngine.");
        }

        return super.init(myConfig);
    }

    /**
     * Write data for key into cache
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     * @link https://secure.php.net/manual/en/function.apcu-store.php
     */
    bool set(myKey, myValue, $ttl = null) {
        myKey = _key(myKey);
        $duration = this.duration($ttl);

        return apcu_store(myKey, myValue, $duration);
    }

    /**
     * Read a key from the cache
     *
     * @param string myKey Identifier for the data
     * @param mixed $default Default value in case the cache misses.
     * @return mixed The cached data, or default if the data doesn"t exist,
     *   has expired, or if there was an error fetching it
     * @link https://secure.php.net/manual/en/function.apcu-fetch.php
     */
    auto get(myKey, $default = null) {
        myValue = apcu_fetch(_key(myKey), $success);
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
     * @link https://secure.php.net/manual/en/function.apcu-inc.php
     */
    function increment(string myKey, int $offset = 1) {
        myKey = _key(myKey);

        return apcu_inc(myKey, $offset);
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     * @link https://secure.php.net/manual/en/function.apcu-dec.php
     */
    function decrement(string myKey, int $offset = 1) {
        myKey = _key(myKey);

        return apcu_dec(myKey, $offset);
    }

    /**
     * Delete a key from the cache
     *
     * @param string myKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     * @link https://secure.php.net/manual/en/function.apcu-delete.php
     */
    bool delete(myKey) {
        myKey = _key(myKey);

        return apcu_delete(myKey);
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
        foreach ($cache["cache_list"] as myKey) {
            if (indexOf(myKey["info"], _config["prefix"]) == 0) {
                apcu_delete(myKey["info"]);
            }
        }

        return true;
    }

    /**
     * Write data for key into cache if it doesn"t exist already.
     * If it already exists, it fails and returns false.
     *
     * @param string myKey Identifier for the data.
     * @param mixed myValue Data to be cached.
     * @return bool True if the data was successfully cached, false on failure.
     * @link https://secure.php.net/manual/en/function.apcu-add.php
     */
    bool add(string myKey, myValue) {
        myKey = _key(myKey);
        $duration = _config["duration"];

        return apcu_add(myKey, myValue, $duration);
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     *
     * @link https://secure.php.net/manual/en/function.apcu-fetch.php
     * @link https://secure.php.net/manual/en/function.apcu-store.php
     */
    string[] groups() {
        if (empty(_compiledGroupNames)) {
            foreach (_config["groups"] as myGroup) {
                _compiledGroupNames[] = _config["prefix"] . myGroup;
            }
        }

        $success = false;
        myGroups = apcu_fetch(_compiledGroupNames, $success);
        if ($success && count(myGroups) !== count(_config["groups"])) {
            foreach (_compiledGroupNames as myGroup) {
                if (!isset(myGroups[myGroup])) {
                    myValue = 1;
                    if (apcu_store(myGroup, myValue) == false) {
                        this.warning(
                            sprintf("Failed to store key "%s" with value "%s" into APCu cache.", myGroup, myValue)
                        );
                    }
                    myGroups[myGroup] = myValue;
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
     * @link https://secure.php.net/manual/en/function.apcu-inc.php
     */
    bool clearGroup(string myGroup) {
        $success = false;
        apcu_inc(_config["prefix"] . myGroup, 1, $success);

        return $success;
    }
}
