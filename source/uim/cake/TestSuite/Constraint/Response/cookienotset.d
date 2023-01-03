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
     */
    bool matches($other) {
        return super.matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "cookie is not set";
    }
}
