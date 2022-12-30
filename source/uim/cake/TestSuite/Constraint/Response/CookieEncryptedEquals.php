module uim.cake.TestSuite\Constraint\Response;

import uim.cake.http.Response;
import uim.cake.utilities.CookieCryptTrait;

/**
 * CookieEncryptedEquals
 *
 * @internal
 */
class CookieEncryptedEquals : CookieEquals
{
    use CookieCryptTrait;

    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     */
    protected string $key;

    /**
     */
    protected string $mode;

    /**
     * Constructor.
     *
     * @param uim.cake.http.Response|null $response A response instance.
     * @param string $cookieName Cookie name
     * @param string $mode Mode
     * @param string $key Key
     */
    this(?Response $response, string $cookieName, string $mode, string $key) {
        super(($response, $cookieName);

        this.key = $key;
        this.mode = $mode;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        $cookie = this.response.getCookie(this.cookieName);

        return $cookie != null && _decrypt($cookie["value"], this.mode) == $other;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("is encrypted in cookie \"%s\"", this.cookieName);
    }

    /**
     * Returns the encryption key
     *
     * @return string
     */
    protected function _getCookieEncryptionKey(): string
    {
        return this.key;
    }
}
