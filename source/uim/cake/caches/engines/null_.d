/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.engines.null_;

@safe:
import uim.cake;

/**
 * Null cache engine, all operations appear to work, but do nothing.
 *
 * This is used internally for when Cache::disable() has been called.
 */
class NullEngine : CacheEngine
{

    bool init(Json aConfig = []) {
        return true;
    }


    bool set(string aKey, $value, $ttl = null) {
        return true;
    }


    bool setMultiple($values, $ttl = null) {
        return true;
    }


    function get(string aKey, $default = null) {
        return $default;
    }


    function getMultiple($keys, $default = null): iterable
    {
        return [];
    }


    function increment(string aKey, int $offset = 1) {
        return 1;
    }


    function decrement(string aKey, int $offset = 1) {
        return 0;
    }


    bool delete($key) {
        return true;
    }


    bool deleteMultiple($keys) {
        return true;
    }


    bool clear() {
        return true;
    }


    bool clearGroup(string $group) {
        return true;
    }
}
