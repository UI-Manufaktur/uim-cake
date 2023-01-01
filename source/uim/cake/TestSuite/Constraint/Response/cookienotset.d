module uim.cake.TestSuite\Constraint\Response;

/**
 * CookieNotSet
 *
 * @internal
 */
class CookieNotSet : CookieSet
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        return super.matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "cookie is not set";
    }
}