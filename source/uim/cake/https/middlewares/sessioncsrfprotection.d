/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.https\Middleware;

use ArrayAccess;
import uim.cake.http.exceptions.InvalidCsrfTokenException;
import uim.cake.http.Session;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;
use RuntimeException;

/**
 * Provides CSRF protection via session based tokens.
 *
 * This middleware adds a CSRF token to the session. Each request must
 * contain a token in request data, or the X-CSRF-Token header on each PATCH, POST,
 * PUT, or DELETE request. This follows a "synchronizer token" pattern.
 *
 * If the request data is missing or does not match the session data,
 * an InvalidCsrfTokenException will be raised.
 *
 * This middleware integrates with the FormHelper automatically and when
 * used together your forms will have CSRF tokens automatically added
 * when `this.Form.create(...)` is used in a view.
 *
 * If you use this middleware *do not* also use CsrfProtectionMiddleware.
 *
 * @see https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#synchronizer-token-pattern
 */
class SessionCsrfProtectionMiddleware : IMiddleware
{
    /**
     * Config for the CSRF handling.
     *
     *  - `key` The session key to use. Defaults to `csrfToken`
     *  - `field` The form field to check. Changing this will also require configuring
     *    FormHelper.
     *
     * @var array<string, mixed>
     */
    protected _config = [
        "key": "csrfToken",
        "field": "_csrfToken",
    ];

    /**
     * Callback for deciding whether to skip the token check for particular request.
     *
     * CSRF protection token check will be skipped if the callback returns `true`.
     *
     * @var callable|null
     */
    protected $skipCheckCallback;

    /**
     * @var int
     */
    const TOKEN_VALUE_LENGTH = 32;

    /**
     * Constructor
     *
     * @param array<string, mixed> aConfig Config options. See _config for valid keys.
     */
    this(Json aConfig = null) {
        _config = aConfig + _config;
    }

    /**
     * Checks and sets the CSRF token depending on the HTTP verb.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        $method = $request.getMethod();
        $hasData = hasAllValues($method, ["PUT", "POST", "DELETE", "PATCH"], true)
            || $request.getParsedBody();

        if (
            $hasData
            && this.skipCheckCallback != null
            && call_user_func(this.skipCheckCallback, $request) == true
        ) {
            $request = this.unsetTokenField($request);

            return $handler.handle($request);
        }

        $session = $request.getAttribute("session");
        if (!$session || !($session instanceof Session)) {
            throw new RuntimeException("You must have a `session` attribute to use session based CSRF tokens");
        }

        $token = $session.read(_config["key"]);
        if ($token == null) {
            $token = this.createToken();
            $session.write(_config["key"], $token);
        }
        $request = $request.withAttribute("csrfToken", this.saltToken($token));

        if ($method == "GET") {
            return $handler.handle($request);
        }

        if ($hasData) {
            this.validateToken($request, $session);
            $request = this.unsetTokenField($request);
        }

        return $handler.handle($request);
    }

    /**
     * Set callback for allowing to skip token check for particular request.
     *
     * The callback will receive request instance as argument and must return
     * `true` if you want to skip token check for the current request.
     *
     * @param callable $callback A callable.
     * @return this
     */
    function skipCheckCallback(callable $callback) {
        this.skipCheckCallback = $callback;

        return this;
    }

    /**
     * Apply entropy to a CSRF token
     *
     * To avoid BREACH apply a random salt value to a token
     * When the token is compared to the session the token needs
     * to be unsalted.
     *
     * @param string aToken The token to salt.
     * @return string The salted token with the salt appended.
     */
    string saltToken(string aToken) {
        $decoded = base64_decode($token);
        $length = strlen($decoded);
        $salt = Security::randomBytes($length);
        $salted = "";
        for ($i = 0; $i < $length; $i++) {
            // XOR the token and salt together so that we can reverse it later.
            $salted ~= chr(ord($decoded[$i]) ^ ord($salt[$i]));
        }

        return base64_encode($salted . $salt);
    }

    /**
     * Remove the salt from a CSRF token.
     *
     * If the token is not TOKEN_VALUE_LENGTH * 2 it is an old
     * unsalted value that is supported for backwards compatibility.
     *
     * @param string aToken The token that could be salty.
     * @return string An unsalted token.
     */
    protected string unsaltToken(string aToken) {
        $decoded = base64_decode($token, true);
        if ($decoded == false || strlen($decoded) != static::TOKEN_VALUE_LENGTH * 2) {
            return $token;
        }
        $salted = substr($decoded, 0, static::TOKEN_VALUE_LENGTH);
        $salt = substr($decoded, static::TOKEN_VALUE_LENGTH);

        $unsalted = "";
        for ($i = 0; $i < static::TOKEN_VALUE_LENGTH; $i++) {
            // Reverse the XOR to desalt.
            $unsalted ~= chr(ord($salted[$i]) ^ ord($salt[$i]));
        }

        return base64_encode($unsalted);
    }

    /**
     * Remove CSRF protection token from request data.
     *
     * This ensures that the token does not cause failures during
     * form tampering protection.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request object.
     * @return \Psr\Http\messages.IServerRequest
     */
    protected function unsetTokenField(IServerRequest $request): IServerRequest
    {
        $body = $request.getParsedBody();
        if (is_array($body)) {
            unset($body[_config["field"]]);
            $request = $request.withParsedBody($body);
        }

        return $request;
    }

    /**
     * Create a new token to be used for CSRF protection
     *
     * This token is a simple unique random value as the compare
     * value is stored in the session where it cannot be tampered with.
     */
    string createToken() {
        return base64_encode(Security::randomBytes(static::TOKEN_VALUE_LENGTH));
    }

    /**
     * Validate the request data against the cookie token.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to validate against.
     * @param uim.cake.http.Session $session The session instance.
     * @return void
     * @throws uim.cake.http.exceptions.InvalidCsrfTokenException When the CSRF token is invalid or missing.
     */
    protected void validateToken(IServerRequest $request, Session $session) {
        $token = $session.read(_config["key"]);
        if (!$token || !is_string($token)) {
            throw new InvalidCsrfTokenException(__d("cake", "Missing or incorrect CSRF session key"));
        }

        $body = $request.getParsedBody();
        if (is_array($body) || $body instanceof ArrayAccess) {
            $post = (string)Hash::get($body, _config["field"]);
            $post = this.unsaltToken($post);
            if (hash_equals($post, $token)) {
                return;
            }
        }

        $header = $request.getHeaderLine("X-CSRF-Token");
        $header = this.unsaltToken($header);
        if (hash_equals($header, $token)) {
            return;
        }

        throw new InvalidCsrfTokenException(__d(
            "cake",
            "CSRF token from either the request body or request headers did not match or is missing."
        ));
    }
}
