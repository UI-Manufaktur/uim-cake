/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.auths.storages;

@safe:
import uim.cake

module uim.cake.auths.storages;

/**
 * Describes the methods that any class representing an Auth data storage should
 * comply with.
 *
 * @mixin uim.cake.Core\InstanceConfigTrait
 */
interface IStorage
{
    /**
     * Read user record.
     *
     * @return \ArrayAccess|array|null
     */
    function read();

    /**
     * Write user record.
     *
     * @param mixed $user array or \ArrayAccess User record.
     */
    void write($user);

    // Delete user record.
    void delete();

    /**
     * Get/set redirect URL.
     *
     * @param mixed $url Redirect URL. If `null` returns current URL. If `false`
     *   deletes currently set URL.
     * @return array|string|null
     */
    function redirectUrl($url = null);
}
