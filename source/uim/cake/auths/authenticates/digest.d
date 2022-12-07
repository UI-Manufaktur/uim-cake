/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auths.authenticates.digest;

@safe:
import uim.cake

/**
 * Digest Authentication adapter for AuthComponent.
 *
 * Provides Digest HTTP authentication support for AuthComponent.
 *
 * ### Using Digest auth
 *
 * Load `AuthComponent` in your controller"s `initialize()` and add "Digest" in "authenticate" key
 *
 * ```
 *  this.loadComponent("Auth", [
 *      "authenticate":["Digest"],
 *      "storage":"Memory",
 *      "unauthorizedRedirect":false,
 *  ]);
 * ```
 *
 * You should set `storage` to `Memory` to prevent UIM from sending a
 * session cookie to the client.
 *
 * You should set `unauthorizedRedirect` to `false`. This causes `AuthComponent` to
 * throw a `ForbiddenException` exception instead of redirecting to another page.
 *
 * Since HTTP Digest Authentication is stateless you don"t need call `setUser()`
 * in your controller. The user credentials will be checked on each request. If
 * valid credentials are not provided, required authentication headers will be sent
 * by this authentication provider which triggers the login dialog in the browser/client.
 *
 * ### Generating passwords compatible with Digest authentication.
 *
 * DigestAuthenticate requires a special password hash that conforms to RFC2617.
 * You can generate this password using `DigestAuthenticate::password()`
 *
 * ```
 * $digestPass = DigestAuthenticate::password(myUsername, myPassword, env("SERVER_NAME"));
 * ```
 *
 * If you wish to use digest authentication alongside other authentication methods,
 * it"s recommended that you store the digest authentication separately. For
 * example `User.digest_pass` could be used for a digest password, while
 * `User.password` would store the password hash for use with other methods like
 * Basic or Form.
 *
 * @see https://book.UIM.org/4/en/controllers/components/authentication.html
 */
class DigestAuthenticate : BasicAuthenticate
{
    /**
     * Constructor
     *
     * Besides the keys specified in BaseAuthenticate::$_defaultConfig,
     * DigestAuthenticate uses the following extra keys:
     *
     * - `secret` The secret to use for nonce validation. Defaults to Security::getSalt().
     * - `realm` The realm authentication is for, Defaults to the servername.
     * - `qop` Defaults to "auth", no other values are supported at this time.
     * - `opaque` A string that must be returned unchanged by clients.
     *    Defaults to `md5(myConfig["realm"])`
     * - `nonceLifetime` The number of seconds that nonces are valid for. Defaults to 300.
     *
     * @param \Cake\Controller\ComponentRegistry $registry The Component registry
     *   used on this request.
     * @param array<string, mixed> myConfig Array of config to use.
     */
    this(ComponentRegistry $registry, array myConfig = []) {
        this.setConfig([
            "nonceLifetime":300,
            "secret":Security::getSalt(),
            "realm":null,
            "qop":"auth",
            "opaque":null,
        ]);

        super.this($registry, myConfig);
    }

    /**
     * Get a user based on information in the request. Used by cookie-less auth for stateless clients.
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return array<string, mixed>|false Either false or an array of user information
     */
    auto getUser(ServerRequest myRequest) {
        $digest = this._getDigest(myRequest);
        if (empty($digest)) {
            return false;
        }

        myUser = this._findUser($digest["username"]);
        if (empty(myUser)) {
            return false;
        }

        if (!this.validNonce($digest["nonce"])) {
            return false;
        }

        myField = this._config["fields"]["password"];
        myPassword = myUser[myField];
        unset(myUser[myField]);

        myRequestMethod = myRequest.getEnv("ORIGINAL_REQUEST_METHOD") ?: myRequest.getMethod();
        $hash = this.generateResponseHash(
            $digest,
            myPassword,
            (string)myRequestMethod
        );
        if (hash_equals($hash, $digest["response"])) {
            return myUser;
        }

        return false;
    }

    /**
     * Gets the digest headers from the request/environment.
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return array<string, mixed>|null Array of digest information.
     */
    protected auto _getDigest(ServerRequest myRequest): ?array
    {
        $digest = myRequest.getEnv("PHP_AUTH_DIGEST");
        if (empty($digest) && function_exists("apache_request_headers")) {
            $headers = apache_request_headers();
            if (!empty($headers["Authorization"]) && substr($headers["Authorization"], 0, 7) == "Digest ") {
                $digest = substr($headers["Authorization"], 7);
            }
        }
        if (empty($digest)) {
            return null;
        }

        return this.parseAuthData($digest);
    }

    /**
     * Parse the digest authentication headers and split them up.
     *
     * @param string $digest The raw digest authentication headers.
     * @return array|null An array of digest authentication headers
     */
    function parseAuthData(string $digest): ?array
    {
        if (substr($digest, 0, 7) == "Digest ") {
            $digest = substr($digest, 7);
        }
        myKeys = $match = [];
        $req = ["nonce":1, "nc":1, "cnonce":1, "qop":1, "username":1, "uri":1, "response":1];
        preg_match_all("/(\w+)=([\""]?)([a-zA-Z0-9\:\#\%\?\&@=\.\/_-]+)\2/", $digest, $match, PREG_SET_ORDER);

        foreach ($match as $i) {
            myKeys[$i[1]] = $i[3];
            unset($req[$i[1]]);
        }

        if (empty($req)) {
            return myKeys;
        }

        return null;
    }

    /**
     * Generate the response hash for a given digest array.
     *
     * @param array<string, mixed> $digest Digest information containing data from DigestAuthenticate::parseAuthData().
     * @param string myPassword The digest hash password generated with DigestAuthenticate::password()
     * @param string $method Request method
     * @return string Response hash
     */
    string generateResponseHash(array $digest, string myPassword, string $method) {
        return md5(
            myPassword .
            ":" . $digest["nonce"] . ":" . $digest["nc"] . ":" . $digest["cnonce"] . ":" . $digest["qop"] . ":" .
            md5($method . ":" . $digest["uri"])
        );
    }

    /**
     * Creates an auth digest password hash to store
     *
     * @param string myUsername The username to use in the digest hash.
     * @param string myPassword The unhashed password to make a digest hash for.
     * @param string $realm The realm the password is for.
     * @return string the hashed password that can later be used with Digest authentication.
     */
    static string password(string myUsername, string myPassword, string $realm) {
        return md5(myUsername . ":" . $realm . ":" . myPassword);
    }

    /**
     * Generate the login headers
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return Headers for logging in.
     */
    STRINGAA loginHeaders(ServerRequest myRequest) {
        $realm = this._config["realm"] ?: myRequest.getEnv("SERVER_NAME");

        myOptions = [
            "realm":$realm,
            "qop":this._config["qop"],
            "nonce":this.generateNonce(),
            "opaque":this._config["opaque"] ?: md5($realm),
        ];

        $digest = this._getDigest(myRequest);
        if ($digest && isset($digest["nonce"]) && !this.validNonce($digest["nonce"])) {
            myOptions["stale"] = true;
        }

        $opts = [];
        foreach (myOptions as $k: $v) {
            if (is_bool($v)) {
                $v = $v ? "true" : "false";
                $opts[] = "%s=%s".format($k, $v);
            } else {
                $opts[] = ˋ%s="%s"ˋ.format($k, $v);
            }
        }

        return [
            "WWW-Authenticate":"Digest " . implode(",", $opts),
        ];
    }

    /**
     * Generate a nonce value that is validated in future requests.
     */
    protected string generateNonce() {
        $expiryTime = microtime(true) + this.getConfig("nonceLifetime");
        $secret = this.getConfig("secret");
        $signatureValue = hash_hmac("sha256", $expiryTime . ":" . $secret, $secret);
        $nonceValue = $expiryTime . ":" . $signatureValue;

        return base64_encode($nonceValue);
    }

    /**
     * Check the nonce to ensure it is valid and not expired.
     *
     * @param string $nonce The nonce value to check.
     */
    protected bool validNonce(string $nonce) {
        myValue = base64_decode($nonce);
        if (myValue == false) {
            return false;
        }
        $parts = explode(":", myValue);
        if (count($parts) !== 2) {
            return false;
        }
        [$expires, $checksum] = $parts;
        if ($expires < microtime(true)) {
            return false;
        }
        $secret = this.getConfig("secret");
        $check = hash_hmac("sha256", $expires . ":" . $secret, $secret);

        return hash_equals($check, $checksum);
    }
}
