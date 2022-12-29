


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Cache;

/**
 * Interface for cache engines that defines methods
 * outside of the PSR16 interface that are used by `Cache`.
 *
 * Internally Cache uses this interface when calling engine
 * methods.
 *
 * @since 3.7.0
 */
interface ICacheEngine
{
    /**
     * Write data for key into a cache engine if it doesn"t exist already.
     *
     * @param string $key Identifier for the data.
     * @param mixed $value Data to be cached - anything except a resource.
     * @return bool True if the data was successfully cached, false on failure.
     *   Or if the key existed already.
     */
    function add(string $key, $value): bool;

    /**
     * Increment a number under the key and return incremented value
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to add
     * @return int|false New incremented value, false otherwise
     */
    function increment(string $key, int $offset = 1);

    /**
     * Decrement a number under the key and return decremented value
     *
     * @param string $key Identifier for the data
     * @param int $offset How much to subtract
     * @return int|false New incremented value, false otherwise
     */
    function decrement(string $key, int $offset = 1);

    /**
     * Clear all values belonging to the named group.
     *
     * Each implementation needs to decide whether actually
     * delete the keys or just augment a group generation value
     * to achieve the same result.
     *
     * @param string $group name of the group to be cleared
     * @return bool
     */
    function clearGroup(string $group): bool;
}
