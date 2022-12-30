module uim.cake.TestSuite\Constraint\Response;

/**
 * CookieSet
 *
 * @internal
 */
class CookieSet : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        $cookie = this.response.getCookie($other);

        return $cookie != null && $cookie["value"] != "";
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return "cookie is set";
    }
}
