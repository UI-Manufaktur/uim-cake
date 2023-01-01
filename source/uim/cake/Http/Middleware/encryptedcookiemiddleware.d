module uim.cake.http.Middleware;

import uim.cake.http.Cookie\CookieCollection;
import uim.cake.http.Response;
import uim.cake.utilities.CookieCryptTrait;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Middleware for encrypting & decrypting cookies.
 *
 * This middleware layer will encrypt/decrypt the named cookies with the given key
 * and cipher type. To support multiple keys/cipher types use this middleware multiple
 * times.
 *
 * Cookies in request data will be decrypted, while cookies in response headers will
 * be encrypted automatically. If the response is a {@link uim.cake.Http\Response}, the cookie
 * data set with `withCookie()` and `cookie()`` will also be encrypted.
 *
 * The encryption types and padding are compatible with those used by CookieComponent
 * for backwards compatibility.
 */
class EncryptedCookieMiddleware : IMiddleware
{
    use CookieCryptTrait;

    /**
     * The list of cookies to encrypt/decrypt
     *
     * @var array<string>
     */
    protected $cookieNames;

    /**
     * Encryption key to use.
     *
     */
    protected string aKey;

    /**
     * Encryption type.
     *
     */
    protected string $cipherType;

    /**
     * Constructor
     *
     * @param array<string> $cookieNames The list of cookie names that should have their values encrypted.
     * @param string aKey The encryption key to use.
     * @param string $cipherType The cipher type to use. Defaults to "aes".
     */
    this(array $cookieNames, string aKey, string $cipherType = "aes") {
        this.cookieNames = $cookieNames;
        this.key = $key;
        this.cipherType = $cipherType;
    }

    /**
     * Apply cookie encryption/decryption.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        if ($request.getCookieParams()) {
            $request = this.decodeCookies($request);
        }

        $response = $handler.handle($request);
        if ($response.hasHeader("Set-Cookie")) {
            $response = this.encodeSetCookieHeader($response);
        }
        if ($response instanceof Response) {
            $response = this.encodeCookies($response);
        }

        return $response;
    }

    /**
     * Fetch the cookie encryption key.
     *
     * Part of the CookieCryptTrait implementation.
     *
     */
    protected string _getCookieEncryptionKey(): string
    {
        return this.key;
    }

    /**
     * Decode cookies from the request.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request to decode cookies from.
     * @return \Psr\Http\messages.IServerRequest Updated request with decoded cookies.
     */
    protected function decodeCookies(IServerRequest $request): IServerRequest
    {
        $cookies = $request.getCookieParams();
        foreach (this.cookieNames as $name) {
            if (isset($cookies[$name])) {
                $cookies[$name] = _decrypt($cookies[$name], this.cipherType, this.key);
            }
        }

        return $request.withCookieParams($cookies);
    }

    /**
     * Encode cookies from a response"s CookieCollection.
     *
     * @param uim.cake.http.Response $response The response to encode cookies in.
     * @return uim.cake.http.Response Updated response with encoded cookies.
     */
    protected function encodeCookies(Response $response): Response
    {
        /** @var array<uim.cake.Http\Cookie\CookieInterface> $cookies */
        $cookies = $response.getCookieCollection();
        foreach ($cookies as $cookie) {
            if (in_array($cookie.getName(), this.cookieNames, true)) {
                $value = _encrypt($cookie.getValue(), this.cipherType);
                $response = $response.withCookie($cookie.withValue($value));
            }
        }

        return $response;
    }

    /**
     * Encode cookies from a response"s Set-Cookie header
     *
     * @param \Psr\Http\messages.IResponse $response The response to encode cookies in.
     * @return \Psr\Http\messages.IResponse Updated response with encoded cookies.
     */
    protected function encodeSetCookieHeader(IResponse $response): IResponse
    {
        /** @var array<uim.cake.Http\Cookie\CookieInterface> $cookies */
        $cookies = CookieCollection::createFromHeader($response.getHeader("Set-Cookie"));
        $header = [];
        foreach ($cookies as $cookie) {
            if (in_array($cookie.getName(), this.cookieNames, true)) {
                $value = _encrypt($cookie.getValue(), this.cipherType);
                $cookie = $cookie.withValue($value);
            }
            $header[] = $cookie.toHeaderValue();
        }

        return $response.withHeader("Set-Cookie", $header);
    }
}
