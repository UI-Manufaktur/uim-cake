
module uim.cake.auths.Storage;

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
     * @return void
     */
    void write($user);

    /**
     * Delete user record.
     */
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
