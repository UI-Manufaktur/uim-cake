module uim.cake.auth\Storage;

@safe:
import uim.cake

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
    protected _user;

    /**
     * Redirect URL.
     *
     * @var array|string|null
     */
    protected _redirectUrl;


    function read() {
        return _user;
    }


    void write(myUser) {
        _user = myUser;
    }


    void delete() {
        ._user = null;
    }


    function redirectUrl(myUrl = null) {
        if (myUrl == null) {
            return _redirectUrl;
        }

        if (myUrl == false) {
            _redirectUrl = null;

            return null;
        }

        _redirectUrl = myUrl;

        return null;
    }
}
