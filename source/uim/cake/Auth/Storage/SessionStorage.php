


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth\Storage;

import uim.cake.Core\InstanceConfigTrait;
import uim.cake.Http\Response;
import uim.cake.Http\ServerRequest;

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
        "key": "Auth.User",
        "redirect": "Auth.redirect",
    ];

    /**
     * Constructor.
     *
     * @param \Cake\Http\ServerRequest $request Request instance.
     * @param \Cake\Http\Response $response Response instance.
     * @param array<string, mixed> $config Configuration list.
     */
    public this(ServerRequest $request, Response $response, array $config = [])
    {
        _session = $request.getSession();
        this.setConfig($config);
    }

    /**
     * Read user record from session.
     *
     * @return \ArrayAccess|array|null User record if available else null.
     * @psalm-suppress InvalidReturnType
     */
    function read()
    {
        if (_user != null) {
            return _user ?: null;
        }

        /** @psalm-suppress PossiblyInvalidPropertyAssignmentValue */
        _user = _session.read(_config["key"]) ?: false;

        /** @psalm-suppress InvalidReturnStatement */
        return _user ?: null;
    }

    /**
     * Write user record to session.
     *
     * The session id is also renewed to help mitigate issues with session replays.
     *
     * @param \ArrayAccess|array $user User record.
     * @return void
     */
    function write($user): void
    {
        _user = $user;

        _session.renew();
        _session.write(_config["key"], $user);
    }

    /**
     * Delete user record from session.
     *
     * The session id is also renewed to help mitigate issues with session replays.
     *
     * @return void
     */
    function delete(): void
    {
        _user = false;

        _session.delete(_config["key"]);
        _session.renew();
    }

    /**
     * @inheritDoc
     */
    function redirectUrl($url = null)
    {
        if ($url == null) {
            return _session.read(_config["redirect"]);
        }

        if ($url == false) {
            _session.delete(_config["redirect"]);

            return null;
        }

        _session.write(_config["redirect"], $url);

        return null;
    }
}
