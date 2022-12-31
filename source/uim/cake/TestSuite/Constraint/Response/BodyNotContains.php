module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyContains
 *
 * @internal
 */
class BodyNotContains : BodyContains
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
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
        return "is not in response body";
    }
}
