
module uim.cake.auths.Storage;

// Memory based non-persistent storage for authenticated user record.
class MemoryStorage : IStorage {
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


    void write($user)
    {
        _user = $user;
    }


    void delete()
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
