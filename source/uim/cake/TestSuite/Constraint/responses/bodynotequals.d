module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyNotEquals
 *
 * @internal
 */
class BodyNotEquals : BodyEquals
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        return super.matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "does not match response body";
    }
}
