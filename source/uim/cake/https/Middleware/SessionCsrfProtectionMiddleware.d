

/**
 * UIM(tm) : Rapid Development Framework (http://UIM.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://UIM.org UIM(tm) Project
 * @since         4.2.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https\Middleware;

use ArrayAccess;
import uim.cake.https\Exception\InvalidCsrfTokenException;
import uim.cake.https\Session;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
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
 * @see https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#sychronizer-token-pattern
 */
class SessionCsrfProtectionMiddleware : MiddlewareInterface
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
    protected $_config = [
        "key" => "csrfToken",
        "field" => "_csrfToken",
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
    public const TOKEN_VALUE_LENGTH = 32;

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Config options. See $_config for valid keys.
     */
    this(array myConfig = []) {
        this._config = myConfig + this._config;
    }

    /**
     * Checks and sets the CSRF token depending on the HTTP verb.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        $method = myRequest.getMethod();
        $hasData = in_array($method, ["PUT", "POST", "DELETE", "PATCH"], true)
            || myRequest.getParsedBody();

        if (
            $hasData
            && this.skipCheckCallback !== null
            && call_user_func(this.skipCheckCallback, myRequest) === true
        ) {
            myRequest = this.unsetTokenField(myRequest);

            return $handler.handle(myRequest);
        }

        $session = myRequest.getAttribute("session");
        if (!$session || !($session instanceof Session)) {
            throw new RuntimeException("You must have a `session` attribute to use session based CSRF tokens");
        }

        $token = $session.read(this._config["key"]);
        if ($token === null) {
            $token = this.createToken();
            $session.write(this._config["key"], $token);
        }
        myRequest = myRequest.withAttribute("csrfToken", this.saltToken($token));

        if ($method === "GET") {
            return $handler.handle(myRequest);
        }

        if ($hasData) {
            this.validateToken(myRequest, $session);
            myRequest = this.unsetTokenField(myRequest);
        }

        return $handler.handle(myRequest);
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
     * @param string $token The token to salt.
     * @return string The salted token with the salt appended.
     */
    string saltToken(string $token) {
        $decoded = base64_decode($token);
        $length = strlen($decoded);
        $salt = Security::randomBytes($length);
        $salted = "";
        for ($i = 0; $i < $length; $i++) {
            // XOR the token and salt together so that we can reverse it later.
            $salted .= chr(ord($decoded[$i]) ^ ord($salt[$i]));
        }

        return base64_encode($salted . $salt);
    }

    /**
     * Remove the salt from a CSRF token.
     *
     * If the token is not TOKEN_VALUE_LENGTH * 2 it is an old
     * unsalted value that is supported for backwards compatibility.
     *
     * @param string $token The token that could be salty.
     * @return string An unsalted token.
     */
    protected string unsaltToken(string $token) {
        $decoded = base64_decode($token, true);
        if ($decoded === false || strlen($decoded) !== static::TOKEN_VALUE_LENGTH * 2) {
            return $token;
        }
        $salted = substr($decoded, 0, static::TOKEN_VALUE_LENGTH);
        $salt = substr($decoded, static::TOKEN_VALUE_LENGTH);

        $unsalted = "";
        for ($i = 0; $i < static::TOKEN_VALUE_LENGTH; $i++) {
            // Reverse the XOR to desalt.
            $unsalted .= chr(ord($salted[$i]) ^ ord($salt[$i]));
        }

        return base64_encode($unsalted);
    }

    /**
     * Remove CSRF protection token from request data.
     *
     * This ensures that the token does not cause failures during
     * form tampering protection.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request object.
     * @return \Psr\Http\Message\IServerRequest
     */
    protected auto unsetTokenField(IServerRequest myRequest): IServerRequest
    {
        $body = myRequest.getParsedBody();
        if (is_array($body)) {
            unset($body[this._config["field"]]);
            myRequest = myRequest.withParsedBody($body);
        }

        return myRequest;
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
     * @param \Psr\Http\Message\IServerRequest myRequest The request to validate against.
     * @param \Cake\Http\Session $session The session instance.
     * @return void
     * @throws \Cake\Http\Exception\InvalidCsrfTokenException When the CSRF token is invalid or missing.
     */
    protected auto validateToken(IServerRequest myRequest, Session $session): void
    {
        $token = $session.read(this._config["key"]);
        if (!$token || !is_string($token)) {
            throw new InvalidCsrfTokenException(__d("cake", "Missing or incorrect CSRF session key"));
        }

        $body = myRequest.getParsedBody();
        if (is_array($body) || $body instanceof ArrayAccess) {
            $post = (string)Hash::get($body, this._config["field"]);
            $post = this.unsaltToken($post);
            if (hash_equals($post, $token)) {
                return;
            }
        }

        $header = myRequest.getHeaderLine("X-CSRF-Token");
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
