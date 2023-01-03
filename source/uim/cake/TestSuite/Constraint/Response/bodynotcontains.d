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
     */
    bool matches($other)
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
