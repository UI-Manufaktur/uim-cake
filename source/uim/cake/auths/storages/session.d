/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auths.storages.session;

@safe:
import uim.cake;

// Session based persistent storage for authenticated user record.
class SessionStorage : IStorage {

    /**
     * User record.
     *
     * Stores user record array if fetched from session or false if session
     * does not have user record.
     *
     * @var \ArrayAccess|array|false|null
     */
    protected _user;

    // Session object.
    protected Session _session;

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
    protected STRINGAA $_defaultConfig = [
        "key": "Auth.User",
        "redirect": "Auth.redirect"];

    /**
     * Constructor.
     *
     * @param uim.cake.http.ServerRequest myRequest Request instance.
     * @param uim.cake.http.Response $response Response instance.
     * @param array<string, mixed> myConfig Configuration list.
     */
    this(ServerRequest myRequest, Response $response, array myConfig = []) {
        _session = myRequest.getSession();
        this.setConfig(myConfig);
    }

    /**
     * Read user record from session.
     *
     * @return \ArrayAccess|array|null User record if available else null.
     * @psalm-suppress InvalidReturnType
     */
    function read() {
        if (_user  !is null) {
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
     * @param \ArrayAccess|array myUser User record.
     */
    void write(myUser) {
        _user = myUser;

        _session.renew();
        _session.write(_config["key"], myUser);
    }

    /**
     * Delete user record from session.
     *
     * The session id is also renewed to help mitigate issues with session replays.
     */
    void delete() {
        _user = false;

        _session.delete(_config["key"]);
        _session.renew();
    }


    function redirectUrl(myUrl = null) {
        if (myUrl is null) {
            return _session.read(_config["redirect"]);
        }

        if (myUrl == false) {
            _session.delete(_config["redirect"]);

            return null;
        }

        _session.write(_config["redirect"], myUrl);

        return null;
    }
}
