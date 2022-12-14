/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches_interface_;

@safe:
import uim.cake;

/**
 * Interface for cache engines that defines methods
 * outside of the PSR16 interface that are used by `Cache`.
 *
 * Internally Cache uses this interface when calling engine
 * methods.
 */
interface ICacheEngine
{
    /**
     * Write data for key into a cache engine if it doesn"t exist already.
     *
     * @param string myKey Identifier for the data.
     * @param mixed myValue Data to be cached - anything except a resource.
     * @return bool True if the data was successfully cached, false on failure.
     *   Or if the key existed already.
     */
    bool add(string myKey, myValue);

    /**
     * Increment a number under the key and return incremented value
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to add
     * @return int|false New incremented value, false otherwise
     */
    function increment(string myKey, int $offset = 1);

    /**
     * Decrement a number under the key and return decremented value
     *
     * @param string myKey Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New incremented value, false otherwise
     */
    function decrement(string myKey, int $offset = 1);

    /**
     * Clear all values belonging to the named group.
     *
     * Each implementation needs to decide whether actually delete the keys or just augment a group generation value
     * to achieve the same result.
     *
     * string myGroup - name of the group to be cleared
     */
    bool clearGroup(string myGroup);
}
