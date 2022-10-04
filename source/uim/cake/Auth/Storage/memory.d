module uim.cake.Auth\Storage;

@safe:
import uim.cake;

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

    /**
     * @inheritDoc
     */
    function read() {
        return this._user;
    }

    /**
     * @inheritDoc
     */
    function write(myUser): void
    {
        this._user = myUser;
    }

    /**
     * @inheritDoc
     */
    function delete(): void
    {
        this._user = null;
    }

    /**
     * @inheritDoc
     */
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
