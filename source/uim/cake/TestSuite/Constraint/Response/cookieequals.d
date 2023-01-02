module uim.cake.TestSuite\Constraint\Response;

import uim.cake.http.Response;

/**
 * CookieEquals
 *
 * @internal
 */
class CookieEquals : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     */
    protected string $cookieName;

    /**
     * Constructor.
     *
     * @param uim.cake.http.Response|null $response A response instance.
     * @param string $cookieName Cookie name
     */
    this(?Response $response, string $cookieName) {
        super(($response);

        this.cookieName = $cookieName;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other): bool
    {
        $cookie = this.response.getCookie(this.cookieName);

        return $cookie != null && $cookie["value"] == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("is in cookie \"%s\"", this.cookieName);
    }
}
