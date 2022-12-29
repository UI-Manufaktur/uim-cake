


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.caches.Engine;

import uim.cake.caches.CacheEngine;

/**
 * Null cache engine, all operations appear to work, but do nothing.
 *
 * This is used internally for when Cache::disable() has been called.
 */
class NullEngine : CacheEngine
{

    bool init(array $config = [])
    {
        return true;
    }


    bool set($key, $value, $ttl = null)
    {
        return true;
    }


    bool setMultiple($values, $ttl = null)
    {
        return true;
    }


    function get($key, $default = null) {
        return $default;
    }


    function getMultiple($keys, $default = null): iterable
    {
        return [];
    }


    function increment(string $key, int $offset = 1) {
        return 1;
    }


    function decrement(string $key, int $offset = 1) {
        return 0;
    }


    bool delete($key)
    {
        return true;
    }


    bool deleteMultiple($keys)
    {
        return true;
    }


    bool clear()
    {
        return true;
    }


    bool clearGroup(string $group)
    {
        return true;
    }
}
