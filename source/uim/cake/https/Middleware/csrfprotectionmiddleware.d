module uim.cake.http.Middleware;

use ArrayAccess;
import uim.cake.http.Cookie\Cookie;
import uim.cake.http.Cookie\CookieInterface;
import uim.cake.http.exceptions.InvalidCsrfTokenException;
import uim.cake.http.Response;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;
use InvalidArgumentException;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;
use RuntimeException;

/**
 * Provides CSRF protection & validation.
 *
 * This middleware adds a CSRF token to a cookie. The cookie value is compared to
 * token in request data, or the X-CSRF-Token header on each PATCH, POST,
 * PUT, or DELETE request. This is known as "double submit cookie" technique.
 *
 * If the request data is missing or does not match the cookie data,
 * an InvalidCsrfTokenException will be raised.
 *
 * This middleware integrates with the FormHelper automatically and when
 * used together your forms will have CSRF tokens automatically added
 * when `this.Form.create(...)` is used in a view.
 *
 * @see https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie
 */
class CsrfProtectionMiddleware : IMiddleware
{
    /**
     * Config for the CSRF handling.
     *
     *  - `cookieName` The name of the cookie to send.
     *  - `expiry` A strotime compatible value of how long the CSRF token should last.
     *    Defaults to browser session.
     *  - `secure` Whether the cookie will be set with the Secure flag. Defaults to false.
     *  - `httponly` Whether the cookie will be set with the HttpOnly flag. Defaults to false.
     *  - `samesite` "SameSite" attribute for cookies. Defaults to `null`.
     *    Valid values: `CookieInterface::SAMESITE_LAX`, `CookieInterface::SAMESITE_STRICT`,
     *    `CookieInterface::SAMESITE_NONE` or `null`.
     *  - `field` The form field to check. Changing this will also require configuring
     *    FormHelper.
     *
     * @var array<string, mixed>
     */
    protected _config = [
        "cookieName": "csrfToken",
        "expiry": 0,
        "secure": false,
        "httponly": false,
        "samesite": null,
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
    const TOKEN_VALUE_LENGTH = 16;

    /**
     * Tokens have an hmac generated so we can ensure
     * that tokens were generated by our application.
     *
     * Should be TOKEN_VALUE_LENGTH + strlen(hmac)
     *
     * We are currently using sha1 for the hmac which
     * creates 40 bytes.
     *
     * @var int
     */
    const TOKEN_WITH_CHECKSUM_LENGTH = 56;

    /**
     * Constructor
     *
     * @param array<string, mixed> aConfig Config options. See _config for valid keys.
     */
    this(Json aConfig = []) {
        if (array_key_exists("httpOnly", aConfig)) {
            aConfig["httponly"] = aConfig["httpOnly"];
            deprecationWarning("Option `httpOnly` is deprecated. Use lowercased `httponly` instead.");
        }

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
        $hasData = in_array($method, ["PUT", "POST", "DELETE", "PATCH"], true)
            || $request.getParsedBody();

        if (
            $hasData
            && this.skipCheckCallback != null
            && call_user_func(this.skipCheckCallback, $request) == true
        ) {
            $request = _unsetTokenField($request);

            return $handler.handle($request);
        }
        if ($request.getAttribute("csrfToken")) {
            throw new RuntimeException(
                "A CSRF token is already set in the request." ~
                "\n" ~
                "Ensure you do not have the CSRF middleware applied more than once~ " ~
                "Check both your `Application::middleware()` method and `config/routes.php`."
            );
        }

        $cookies = $request.getCookieParams();
        $cookieData = Hash::get($cookies, _config["cookieName"]);

        if (is_string($cookieData) && $cookieData != "") {
            try {
                $request = $request.withAttribute("csrfToken", this.saltToken($cookieData));
            } catch (InvalidArgumentException $e) {
                $cookieData = null;
            }
        }

        if ($method == "GET" && $cookieData == null) {
            $token = this.createToken();
            $request = $request.withAttribute("csrfToken", this.saltToken($token));
            /** @var mixed $response */
            $response = $handler.handle($request);

            return _addTokenCookie($token, $request, $response);
        }

        if ($hasData) {
            _validateToken($request);
            $request = _unsetTokenField($request);
        }

        return $handler.handle($request);
    }

    /**
     * Set callback for allowing to skip token check for particular request.
     *
     * The callback will receive request instance as argument and must return
     * `true` if you want to skip token check for the current request.
     *
     * @deprecated 4.1.0 Use skipCheckCallback instead.
     * @param callable $callback A callable.
     * @return this
     */
    function whitelistCallback(callable $callback) {
        deprecationWarning("`whitelistCallback()` is deprecated. Use `skipCheckCallback()` instead.");
        this.skipCheckCallback = $callback;

        return this;
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
     * Remove CSRF protection token from request data.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request object.
     * @return \Psr\Http\messages.IServerRequest
     */
    protected function _unsetTokenField(IServerRequest $request): IServerRequest
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
     * @return string
     * @deprecated 4.0.6 Use {@link createToken()} instead.
     */
    protected string _createToken() {
        deprecationWarning("_createToken() is deprecated. Use createToken() instead.");

        return this.createToken();
    }

    /**
     * Test if the token predates salted tokens.
     *
     * These tokens are hexadecimal values and equal
     * to the token with checksum length. While they are vulnerable
     * to BREACH they should rotate over time and support will be dropped
     * in 5.x.
     *
     * @param string aToken The token to test.
     */
    protected bool isHexadecimalToken(string aToken) {
        return preg_match("/^[a-f0-9]{" ~ static::TOKEN_WITH_CHECKSUM_LENGTH ~ "}$/", $token) == 1;
    }

    /**
     * Create a new token to be used for CSRF protection
     */
    string createToken() {
        $value = Security::randomBytes(static::TOKEN_VALUE_LENGTH);

        return base64_encode($value . hash_hmac("sha1", $value, Security::getSalt()));
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
        if (this.isHexadecimalToken($token)) {
            return $token;
        }
        $decoded = base64_decode($token, true);
        if ($decoded == false) {
            throw new InvalidArgumentException("Invalid token data.");
        }

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
     * @param string aToken The token that could be salty.
     * @return string An unsalted token.
     */
    string unsaltToken(string aToken) {
        if (this.isHexadecimalToken($token)) {
            return $token;
        }
        $decoded = base64_decode($token, true);
        if ($decoded == false || strlen($decoded) != static::TOKEN_WITH_CHECKSUM_LENGTH * 2) {
            return $token;
        }
        $salted = substr($decoded, 0, static::TOKEN_WITH_CHECKSUM_LENGTH);
        $salt = substr($decoded, static::TOKEN_WITH_CHECKSUM_LENGTH);

        $unsalted = "";
        for ($i = 0; $i < static::TOKEN_WITH_CHECKSUM_LENGTH; $i++) {
            // Reverse the XOR to desalt.
            $unsalted .= chr(ord($salted[$i]) ^ ord($salt[$i]));
        }

        return base64_encode($unsalted);
    }

    /**
     * Verify that CSRF token was originally generated by the receiving application.
     *
     * @param string aToken The CSRF token.
     */
    protected bool _verifyToken(string aToken) {
        // If we have a hexadecimal value we"re in a compatibility mode from before
        // tokens were salted on each request.
        if (this.isHexadecimalToken($token)) {
            $decoded = $token;
        } else {
            $decoded = base64_decode($token, true);
        }
        if (!$decoded || strlen($decoded) <= static::TOKEN_VALUE_LENGTH) {
            return false;
        }

        $key = substr($decoded, 0, static::TOKEN_VALUE_LENGTH);
        $hmac = substr($decoded, static::TOKEN_VALUE_LENGTH);

        $expectedHmac = hash_hmac("sha1", $key, Security::getSalt());

        return hash_equals($hmac, $expectedHmac);
    }

    /**
     * Add a CSRF token to the response cookies.
     *
     * @param string aToken The token to add.
     * @param \Psr\Http\messages.IServerRequest $request The request to validate against.
     * @param \Psr\Http\messages.IResponse $response The response.
     * @return \Psr\Http\messages.IResponse $response Modified response.
     */
    protected function _addTokenCookie(
        string aToken,
        IServerRequest $request,
        IResponse $response
    ): IResponse {
        $cookie = _createCookie($token, $request);
        if ($response instanceof Response) {
            return $response.withCookie($cookie);
        }

        return $response.withAddedHeader("Set-Cookie", $cookie.toHeaderValue());
    }

    /**
     * Validate the request data against the cookie token.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to validate against.
     * @return void
     * @throws uim.cake.http.exceptions.InvalidCsrfTokenException When the CSRF token is invalid or missing.
     */
    protected void _validateToken(IServerRequest $request) {
        $cookie = Hash::get($request.getCookieParams(), _config["cookieName"]);

        if (!$cookie || !is_string($cookie)) {
            throw new InvalidCsrfTokenException(__d("cake", "Missing or incorrect CSRF cookie type."));
        }

        if (!_verifyToken($cookie)) {
            $exception = new InvalidCsrfTokenException(__d("cake", "Missing or invalid CSRF cookie."));

            $expiredCookie = _createCookie("", $request).withExpired();
            $exception.setHeader("Set-Cookie", $expiredCookie.toHeaderValue());

            throw $exception;
        }

        $body = $request.getParsedBody();
        if (is_array($body) || $body instanceof ArrayAccess) {
            $post = (string)Hash::get($body, _config["field"]);
            $post = this.unsaltToken($post);
            if (hash_equals($post, $cookie)) {
                return;
            }
        }

        $header = $request.getHeaderLine("X-CSRF-Token");
        $header = this.unsaltToken($header);
        if (hash_equals($header, $cookie)) {
            return;
        }

        throw new InvalidCsrfTokenException(__d(
            "cake",
            "CSRF token from either the request body or request headers did not match or is missing."
        ));
    }

    /**
     * Create response cookie
     *
     * @param string aValue Cookie value
     * @param \Psr\Http\messages.IServerRequest $request The request object.
     * @return uim.cake.http.Cookie\CookieInterface
     */
    protected function _createCookie(string aValue, IServerRequest $request): CookieInterface
    {
        return Cookie::create(
            _config["cookieName"],
            $value,
            [
                "expires": _config["expiry"] ?: null,
                "path": $request.getAttribute("webroot"),
                "secure": _config["secure"],
                "httponly": _config["httponly"],
                "samesite": _config["samesite"],
            ]
        );
    }
}
