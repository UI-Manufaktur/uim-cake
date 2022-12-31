module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyNotEmpty
 *
 * @internal
 */
class BodyNotEmpty : BodyEmpty
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
        return "response body is not empty";
    }
}
