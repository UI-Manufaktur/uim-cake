


 *


 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.auths.Storage;

/**
 * Memory based non-persistent storage for authenticated user record.
 */
class MemoryStorage : IStorage
{
    /**
     * User record.
     *
     * @var \ArrayAccess|array|null
     */
    protected $_user;

    /**
     * Redirect URL.
     *
     * @var array|string|null
     */
    protected $_redirectUrl;


    function read() {
        return _user;
    }


    function write($user): void
    {
        _user = $user;
    }


    function delete(): void
    {
        _user = null;
    }


    function redirectUrl($url = null) {
        if ($url == null) {
            return _redirectUrl;
        }

        if ($url == false) {
            _redirectUrl = null;

            return null;
        }

        _redirectUrl = $url;

        return null;
    }
}
