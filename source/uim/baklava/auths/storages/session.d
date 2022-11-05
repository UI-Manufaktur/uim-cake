module uim.baklava.Auth\Storage;

@safe:
import uim.baklava;

import uim.baklava.core.InstanceConfigTrait;
import uim.baklava.https\Response;
import uim.baklava.https\ServerRequest;

/**
 * Session based persistent storage for authenticated user record.
 */
class SessionStorage : IStorage
{
    use InstanceConfigTrait;

    /**
     * User record.
     *
     * Stores user record array if fetched from session or false if session
     * does not have user record.
     *
     * @var \ArrayAccess|array|false|null
     */
    protected $_user;

    /**
     * Session object.
     *
     * @var \Cake\Http\Session
     */
    protected $_session;

    /**
     * Default configuration for this class.
     *
     * Keys:
     *
     * - `key` - Session key used to store user record.
     * - `redirect` - Session key used to store redirect URL.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'key' => 'Auth.User',
        'redirect' => 'Auth.redirect',
    ];

    /**
     * Constructor.
     *
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     * @param \Cake\Http\Response $response Response instance.
     * @param array<string, mixed> myConfig Configuration list.
     */
    this(ServerRequest myRequest, Response $response, array myConfig = []) {
        this._session = myRequest.getSession();
        this.setConfig(myConfig);
    }

    /**
     * Read user record from session.
     *
     * @return \ArrayAccess|array|null User record if available else null.
     * @psalm-suppress InvalidReturnType
     */
    function read() {
        if (this._user !== null) {
            return this._user ?: null;
        }

        /** @psalm-suppress PossiblyInvalidPropertyAssignmentValue */
        this._user = this._session.read(this._config['key']) ?: false;

        /** @psalm-suppress InvalidReturnStatement */
        return this._user ?: null;
    }

    /**
     * Write user record to session.
     *
     * The session id is also renewed to help mitigate issues with session replays.
     *
     * @param \ArrayAccess|array myUser User record.
     * @return void
     */
    void write(myUser) {
        this._user = myUser;

        this._session.renew();
        this._session.write(this._config['key'], myUser);
    }

    /**
     * Delete user record from session.
     *
     * The session id is also renewed to help mitigate issues with session replays.
     */
    void delete() {
        this._user = false;

        this._session.delete(this._config['key']);
        this._session.renew();
    }


    function redirectUrl(myUrl = null) {
        if (myUrl === null) {
            return this._session.read(this._config['redirect']);
        }

        if (myUrl === false) {
            this._session.delete(this._config['redirect']);

            return null;
        }

        this._session.write(this._config['redirect'], myUrl);

        return null;
    }
}
