module uim.cake.https\Middleware;

import uim.cake.https\Cookie\CookieCollection;
import uim.cake.https\Response;
import uim.cake.utilities.CookieCryptTrait;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * Middleware for encrypting & decrypting cookies.
 *
 * This middleware layer will encrypt/decrypt the named cookies with the given key
 * and cipher type. To support multiple keys/cipher types use this middleware multiple
 * times.
 *
 * Cookies in request data will be decrypted, while cookies in response headers will
 * be encrypted automatically. If the response is a {@link \Cake\Http\Response}, the cookie
 * data set with `withCookie()` and `cookie()`` will also be encrypted.
 *
 * The encryption types and padding are compatible with those used by CookieComponent
 * for backwards compatibility.
 */
class EncryptedCookieMiddleware : MiddlewareInterface
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
     */
    protected string myKey;

    /**
     * Encryption type.
     */
    protected string $cipherType;

    /**
     * Constructor
     *
     * @param array<string> $cookieNames The list of cookie names that should have their values encrypted.
     * @param string myKey The encryption key to use.
     * @param string $cipherType The cipher type to use. Defaults to "aes".
     */
    this(array $cookieNames, string myKey, string $cipherType = "aes") {
        this.cookieNames = $cookieNames;
        this.key = myKey;
        this.cipherType = $cipherType;
    }

    /**
     * Apply cookie encryption/decryption.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        if (myRequest.getCookieParams()) {
            myRequest = this.decodeCookies(myRequest);
        }

        $response = $handler.handle(myRequest);
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
     * @return string
     */
    protected string _getCookieEncryptionKey() {
        return this.key;
    }

    /**
     * Decode cookies from the request.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to decode cookies from.
     * @return \Psr\Http\Message\IServerRequest Updated request with decoded cookies.
     */
    protected auto decodeCookies(IServerRequest myRequest): IServerRequest
    {
        $cookies = myRequest.getCookieParams();
        foreach (this.cookieNames as myName) {
            if (isset($cookies[myName])) {
                $cookies[myName] = this._decrypt($cookies[myName], this.cipherType, this.key);
            }
        }

        return myRequest.withCookieParams($cookies);
    }

    /**
     * Encode cookies from a response"s CookieCollection.
     *
     * @param \Cake\Http\Response $response The response to encode cookies in.
     * @return \Cake\Http\Response Updated response with encoded cookies.
     */
    protected auto encodeCookies(Response $response): Response
    {
        /** @var array<\Cake\Http\Cookie\ICookie> $cookies */
        $cookies = $response.getCookieCollection();
        foreach ($cookies as $cookie) {
            if (in_array($cookie.getName(), this.cookieNames, true)) {
                myValue = this._encrypt($cookie.getValue(), this.cipherType);
                $response = $response.withCookie($cookie.withValue(myValue));
            }
        }

        return $response;
    }

    /**
     * Encode cookies from a response"s Set-Cookie header
     *
     * @param \Psr\Http\Message\IResponse $response The response to encode cookies in.
     * @return \Psr\Http\Message\IResponse Updated response with encoded cookies.
     */
    protected auto encodeSetCookieHeader(IResponse $response): IResponse
    {
        /** @var array<\Cake\Http\Cookie\ICookie> $cookies */
        $cookies = CookieCollection::createFromHeader($response.getHeader("Set-Cookie"));
        $header = [];
        foreach ($cookies as $cookie) {
            if (in_array($cookie.getName(), this.cookieNames, true)) {
                myValue = this._encrypt($cookie.getValue(), this.cipherType);
                $cookie = $cookie.withValue(myValue);
            }
            $header[] = $cookie.toHeaderValue();
        }

        return $response.withHeader("Set-Cookie", $header);
    }
}
