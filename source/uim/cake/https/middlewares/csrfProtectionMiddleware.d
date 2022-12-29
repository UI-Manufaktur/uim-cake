module uim.cake.https\Middleware;

use ArrayAccess;
import uim.cake.https\Cookie\Cookie;
import uim.cake.https\Cookie\ICookie;
import uim.cake.https\Exception\InvalidCsrfTokenException;
import uim.cake.https\Response;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;
use InvalidArgumentException;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IMiddleware;
use Psr\Http\Server\IRequestHandler;
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
     *    Valid values: `ICookie::SAMESITE_LAX`, `ICookie::SAMESITE_STRICT`,
     *    `ICookie::SAMESITE_NONE` or `null`.
     *  - `field` The form field to check. Changing this will also require configuring
     *    FormHelper.
     *
     * @var array<string, mixed>
     */
    protected _config = [
        "cookieName":"csrfToken",
        "expiry":0,
        "secure":false,
        "httponly":false,
        "samesite":null,
        "field":"_csrfToken",
    ];

    /**
     * Callback for deciding whether to skip the token check for particular request.
     *
     * CSRF protection token check will be skipped if the callback returns `true`.
     *
     * @var callable|null
     */
    protected skipCheckCallback;

    /**
     * @var int
     */
    public const TOKEN_VALUE_LENGTH = 16;

    /**
     * Tokens have an hmac generated so we can ensure
     * that tokens were generated by our application.
     *
     * Should be TOKEN_VALUE_LENGTH + strlen(hmac)
     *
     * We are currently using sha1 for the hmac which
     * creates 40 bytes.
    */
    public const int TOKEN_WITH_CHECKSUM_LENGTH = 56;

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Config options. See $_config for valid keys.
     */
    this(array myConfig = []) {
        if (array_key_exists("httpOnly", myConfig)) {
            myConfig["httponly"] = myConfig["httpOnly"];
            deprecationWarning("Option `httpOnly` is deprecated. Use lowercased `httponly` instead.");
        }

        _config = myConfig + _config;
    }

    /**
     * Checks and sets the CSRF token depending on the HTTP verb.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\IRequestHandler $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, IRequestHandler $handler): IResponse
    {
        $method = myRequest.getMethod();
        $hasData = in_array($method, ["PUT", "POST", "DELETE", "PATCH"], true)
            || myRequest.getParsedBody();

        if (
            $hasData
            && this.skipCheckCallback  !is null
            && call_user_func(this.skipCheckCallback, myRequest) == true
        ) {
            myRequest = _unsetTokenField(myRequest);

            return $handler.handle(myRequest);
        }
        if (myRequest.getAttribute("csrfToken")) {
            throw new RuntimeException(
                "A CSRF token is already set in the request." .
                "\n" .
                "Ensure you do not have the CSRF middleware applied more than once. " .
                "Check both your `Application::middleware()` method and `config/routes.php`."
            );
        }

        $cookies = myRequest.getCookieParams();
        $cookieData = Hash::get($cookies, _config["cookieName"]);

        if (is_string($cookieData) && $cookieData != "") {
            try {
                myRequest = myRequest.withAttribute("csrfToken", this.saltToken($cookieData));
            } catch (InvalidArgumentException $e) {
                $cookieData = null;
            }
        }

        if ($method == "GET" && $cookieData is null) {
            $token = this.createToken();
            myRequest = myRequest.withAttribute("csrfToken", this.saltToken($token));
            /** @var mixed $response */
            $response = $handler.handle(myRequest);

            return _addTokenCookie($token, myRequest, $response);
        }

        if ($hasData) {
            _validateToken(myRequest);
            myRequest = _unsetTokenField(myRequest);
        }

        return $handler.handle(myRequest);
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
     * @param \Psr\Http\Message\IServerRequest myRequest The request object.
     * @return \Psr\Http\Message\IServerRequest
     */
    protected auto _unsetTokenField(IServerRequest myRequest): IServerRequest
    {
        $body = myRequest.getParsedBody();
        if (is_array($body)) {
            unset($body[_config["field"]]);
            myRequest = myRequest.withParsedBody($body);
        }

        return myRequest;
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
     * @param string token The token to test.
     */
    protected bool isHexadecimalToken(string token) {
        return preg_match("/^[a-f0-9]{" . static::TOKEN_WITH_CHECKSUM_LENGTH . "}$/", $token) == 1;
    }

    /**
     * Create a new token to be used for CSRF protection
     */
    string createToken() {
        myValue = Security::randomBytes(static::TOKEN_VALUE_LENGTH);

        return base64_encode(myValue . hash_hmac("sha1", myValue, Security::getSalt()));
    }

    /**
     * Apply entropy to a CSRF token
     *
     * To avoid BREACH apply a random salt value to a token
     * When the token is compared to the session the token needs
     * to be unsalted.
     *
     * @param string token The token to salt.
     * @return string The salted token with the salt appended.
     */
    string saltToken(string token) {
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
     * @param string token The token that could be salty.
     * @return string An unsalted token.
     */
    string unsaltToken(string token) {
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
     * @param string token The CSRF token.
     */
    protected bool _verifyToken(string token) {
        // If we have a hexadecimal value we"re in a compatibility mode from before
        // tokens were salted on each request.
        if (this.isHexadecimalToken($token)) {
            $decoded = $token;
        } else {
            $decoded = base64_decode($token, true);
        }
        if (strlen($decoded) <= static::TOKEN_VALUE_LENGTH) {
            return false;
        }

        myKey = substr($decoded, 0, static::TOKEN_VALUE_LENGTH);
        $hmac = substr($decoded, static::TOKEN_VALUE_LENGTH);

        $expectedHmac = hash_hmac("sha1", myKey, Security::getSalt());

        return hash_equals($hmac, $expectedHmac);
    }

    /**
     * Add a CSRF token to the response cookies.
     *
     * @param string token The token to add.
     * @param \Psr\Http\Message\IServerRequest myRequest The request to validate against.
     * @param \Psr\Http\Message\IResponse $response The response.
     * @return \Psr\Http\Message\IResponse $response Modified response.
     */
    protected auto _addTokenCookie(
        string token,
        IServerRequest myRequest,
        IResponse $response
    ): IResponse {
        $cookie = _createCookie($token, myRequest);
        if ($response instanceof Response) {
            return $response.withCookie($cookie);
        }

        return $response.withAddedHeader("Set-Cookie", $cookie.toHeaderValue());
    }

    /**
     * Validate the request data against the cookie token.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to validate against.
     * @return void
     * @throws uim.cake.http.Exception\InvalidCsrfTokenException When the CSRF token is invalid or missing.
     */
    protected auto _validateToken(IServerRequest myRequest): void
    {
        $cookie = Hash::get(myRequest.getCookieParams(), _config["cookieName"]);

        if (!$cookie || !is_string($cookie)) {
            throw new InvalidCsrfTokenException(__d("cake", "Missing or incorrect CSRF cookie type."));
        }

        if (!_verifyToken($cookie)) {
            myException = new InvalidCsrfTokenException(__d("cake", "Missing or invalid CSRF cookie."));

            $expiredCookie = _createCookie("", myRequest).withExpired();
            myException.setHeader("Set-Cookie", $expiredCookie.toHeaderValue());

            throw myException;
        }

        $body = myRequest.getParsedBody();
        if (is_array($body) || $body instanceof ArrayAccess) {
            $post = (string)Hash::get($body, _config["field"]);
            $post = this.unsaltToken($post);
            if (hash_equals($post, $cookie)) {
                return;
            }
        }

        $header = myRequest.getHeaderLine("X-CSRF-Token");
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
     * @param string myValue Cookie value
     * @param \Psr\Http\Message\IServerRequest myRequest The request object.
     * @return uim.cake.http.Cookie\ICookie
     */
    protected auto _createCookie(string myValue, IServerRequest myRequest): ICookie
    {
        $cookie = Cookie::create(
            _config["cookieName"],
            myValue,
            [
                "expires":_config["expiry"] ?: null,
                "path":myRequest.getAttribute("webroot"),
                "secure":_config["secure"],
                "httponly":_config["httponly"],
                "samesite":_config["samesite"],
            ]
        );

        return $cookie;
    }
}
