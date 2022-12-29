module uim.cake.auth\Storage;

@safe:
import uim.cake

/**
 * Describes the methods that any class representing an Auth data storage should
 * comply with.
 *
 * @mixin uim.cake.Core\InstanceConfigTrait
 */
interface IStorage {
    /**
     * Read user record.
     * @return \ArrayAccess|array|null
     */
    string[] read();

    /**
     * Write user record.
     *
     * @param mixed myUser array or \ArrayAccess User record.
     */
    void write(myUser);

    /**
     * Delete user record.
     */
    void delete();

    /**
     * Get/set redirect URL.
     *
     * @param mixed myUrl Redirect URL. If `null` returns current URL. If `false`
     *   deletes currently set URL.
     * @return array|string|null
     */
    string[] redirectUrl(myUrl = null);
}
