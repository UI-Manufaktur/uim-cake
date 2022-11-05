

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.caches.engines;

import uim.baklava.caches\CacheEngine;

/**
 * Array storage engine for cache.
 *
 * Not actually a persistent cache engine. All data is only
 * stored in memory for the duration of a single process. While not
 * useful in production settings this engine can be useful in tests
 * or console tools where you don't want the overhead of interacting
 * with a cache servers, but want the work saving properties a cache
 * provides.
 */
class ArrayEngine : CacheEngine
{
    /**
     * Cached data.
     *
     * Structured as [key => [exp => expiration, val => value]]
     *
     * @var array
     */
    protected myData = [];

    /**
     * Write data for key into cache
     *
     * @param string myKey Identifier for the data
     * @param mixed myValue Data to be cached
     * @param \DateInterval|int|null $ttl Optional. The TTL value of this item. If no value is sent and
     *   the driver supports TTL then the library may set a default value
     *   for it or let the driver take care of that.
     * @return bool True on success and false on failure.
     */
    bool set(myKey, myValue, $ttl = null)
    {
        myKey = this._key(myKey);
        $expires = time() + this.duration($ttl);
        this.data[myKey] = ['exp' => $expires, 'val' => myValue];

        return true;
    }

    /**
     * Read a key from the cache
     *
     * @param string myKey Identifier for the data
     * @param mixed $default Default value to return if the key does not exist.
     * @return mixed The cached data, or default value if the data doesn't exist, has
     * expired, or if there was an error fetching it.
     */
    auto get(myKey, $default = null) {
        myKey = this._key(myKey);
        if (!isset(this.data[myKey])) {
            return $default;
        }
        myData = this.data[myKey];

        // Check expiration
        $now = time();
        if (myData['exp'] <= $now) {
            unset(this.data[myKey]);

            return $default;
        }

        return myData['val'];
    }

    /**
     * Increments the value of an integer cached key
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to increment
     * @return int|false New incremented value, false otherwise
     */
    function increment(string myKey, int $offset = 1) {
        if (this.get(myKey) === null) {
            this.set(myKey, 0);
        }
        myKey = this._key(myKey);
        this.data[myKey]['val'] += $offset;

        return this.data[myKey]['val'];
    }

    /**
     * Decrements the value of an integer cached key
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New decremented value, false otherwise
     */
    function decrement(string myKey, int $offset = 1) {
        if (this.get(myKey) === null) {
            this.set(myKey, 0);
        }
        myKey = this._key(myKey);
        this.data[myKey]['val'] -= $offset;

        return this.data[myKey]['val'];
    }

    /**
     * Delete a key from the cache
     *
     * @param string myKey Identifier for the data
     * @return bool True if the value was successfully deleted, false if it didn't exist or couldn't be removed
     */
    bool delete(myKey)
    {
        myKey = this._key(myKey);
        unset(this.data[myKey]);

        return true;
    }

    /**
     * Delete all keys from the cache. This will clear every cache config using APC.
     *
     * @return bool True Returns true.
     */
    bool clear()
    {
        this.data = [];

        return true;
    }

    /**
     * Returns the `group value` for each of the configured groups
     * If the group initial value was not found, then it initializes
     * the group accordingly.
     *
     * @return array<string>
     */
    function groups(): array
    {
        myResult = [];
        foreach (this._config['groups'] as myGroup) {
            myKey = this._config['prefix'] . myGroup;
            if (!isset(this.data[myKey])) {
                this.data[myKey] = ['exp' => PHP_INT_MAX, 'val' => 1];
            }
            myValue = this.data[myKey]['val'];
            myResult[] = myGroup . myValue;
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
    bool clearGroup(string myGroup)
    {
        myKey = this._config['prefix'] . myGroup;
        if (isset(this.data[myKey])) {
            this.data[myKey]['val'] += 1;
        }

        return true;
    }
}
