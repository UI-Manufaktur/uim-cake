/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.engines.array_;

@safe:
import uim.cake;

/**
 * Array storage engine for cache.
 *
 * Not actually a persistent cache engine. All data is only
 * stored in memory for the duration of a single process. While not
 * useful in production settings this engine can be useful in tests
 * or console tools where you don"t want the overhead of interacting
 * with a cache servers, but want the work saving properties a cache
 * provides.
 */
class ArrayEngine : CacheEngine {
    /**
     * Cached data.
     *
     * Structured as [key: [exp: expiration, val: value]]
     */
    protected array<string, array> $data = [];

    /**
     * Write data for key into cache
     *
     * @param string string aKey Identifier for the data
     * @param mixed $value Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     */
    bool set(string aKey, $value, $ttl = null) {
        string aKey = _key(string aKey);
        $expires = time() + this.duration($ttl);
        this.data[string aKey] = ["exp": $expires, "val": $value];

        return true;
    }

    /**
     * Read a key from the cache
     *
     * @param string string aKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn"t exist, has
     * expired, or if there was an error fetching it.
     */
    function get(string aKey, $default = null) {
        string aKey = _key(string aKey);
        if (!isset(this.data[string aKey])) {
            return $default;
        }
        $data = this.data[string aKey];

        // Check expiration
        $now = time();
        if ($data["exp"] <= $now) {
            unset(this.data[string aKey]);

            return $default;
        }

        return $data["val"];
    }

    /**
     * Increments the value of an integer cached key
     *
     * @param string string aKey Identifier for the data
     * @param int anOffset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string string aKey, int anOffset = 1) {
        if (this.get(string aKey) == null) {
            this.set(string aKey, 0);
        }
        string aKey = _key(string aKey);
        this.data[string aKey]["val"] += anOffset;

        return this.data[string aKey]["val"];
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string string aKey Identifier for the data
     * @param int anOffset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string string aKey, int anOffset = 1) {
        if (this.get(string aKey) == null) {
            this.set(string aKey, 0);
        }
        string aKey = _key(string aKey);
        this.data[string aKey]["val"] -= anOffset;

        return this.data[string aKey]["val"];
    }

    /**
     * Delete a key from the cache
     *
     * @param string string aKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn"t exist or couldn"t be removed
     */
    bool delete(string aKey) {
        string aKey = _key(string aKey);
        unset(this.data[string aKey]);

        return true;
    }

    /**
     * Delete all keys from the cache. This will clear every cache config using APC.
     *
     * @return bool True Returns true.
     */
    bool clear() {
        this.data = [];

        return true;
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     */
    string[] groups() {
        $result = [];
        foreach (_config["groups"] as $group) {
            string aKey = _config["prefix"] . $group;
            if (!isset(this.data[string aKey])) {
                this.data[string aKey] = ["exp": PHP_INT_MAX, "val": 1];
            }
            $value = this.data[string aKey]["val"];
            $result[] = $group . $value;
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
        string aKey = _config["prefix"] . $group;
        if (isset(this.data[string aKey])) {
            this.data[string aKey]["val"] += 1;
        }

        return true;
    }
}
