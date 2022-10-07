module uim.cake.cache\Engine;

import uim.cake.cache\CacheEngine;

/**
 * Null cache engine, all operations appear to work, but do nothing.
 *
 * This is used internally for when Cache::disable() has been called.
 */
class NullEngine : CacheEngine
{
    bool init(array myConfig = []) {
        return true;
    }

    bool set(myKey, myValue, $ttl = null) {
        return true;
    }

    bool setMultiple(myValues, $ttl = null) {
        return true;
    }


    auto get(myKey, $default = null)
    {
        return $default;
    }


    auto getMultiple(myKeys, $default = null): iterable
    {
        return [];
    }


    function increment(string myKey, int $offset = 1)
    {
        return 1;
    }


    function decrement(string myKey, int $offset = 1)
    {
        return 0;
    }

    bool delete(myKey) {
        return true;
    }

    bool deleteMultiple(myKeys) {
        return true;
    }

    bool clear() {
        return true;
    }

    bool clearGroup(string $group) {
        return true;
    }
}
