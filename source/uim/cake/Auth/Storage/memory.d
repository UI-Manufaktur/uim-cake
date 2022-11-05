module uim.baklava.Auth\Storage;

@safe:
import uim.baklava;

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
        return this._user;
    }


    void write(myUser) {
        this._user = myUser;
    }


    void delete() {
        this._user = null;
    }


    function redirectUrl(myUrl = null) {
        if (myUrl === null) {
            return this._redirectUrl;
        }

        if (myUrl === false) {
            this._redirectUrl = null;

            return null;
        }

        this._redirectUrl = myUrl;

        return null;
    }
}
