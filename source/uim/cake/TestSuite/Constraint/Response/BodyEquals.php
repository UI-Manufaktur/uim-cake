module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyEquals
 *
 * @internal
 */
class BodyEquals : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        return _getBodyAsString() == $other;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return "matches response body";
    }
}
