


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth\Storage;

/**
 * Describes the methods that any class representing an Auth data storage should
 * comply with.
 *
 * @mixin \Cake\Core\InstanceConfigTrait
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
    function write($user): void;

    /**
     * Delete user record.
     *
     * @return void
     */
    function delete(): void;

    /**
     * Get/set redirect URL.
     *
     * @param mixed $url Redirect URL. If `null` returns current URL. If `false`
     *   deletes currently set URL.
     * @return array|string|null
     */
    function redirectUrl($url = null);
}
