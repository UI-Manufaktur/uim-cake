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
     */
    bool matches($other) {
        return _getBodyAsString() == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "matches response body";
    }
}
