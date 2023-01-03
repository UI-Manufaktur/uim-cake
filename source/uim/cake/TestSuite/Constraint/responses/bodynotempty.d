module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyNotEmpty
 *
 * @internal
 */
class BodyNotEmpty : BodyEmpty {
    /**
     * Checks assertion
     * @param mixed $other Expected type
     */
    bool matches($other) {
        return super.matches($other) == false;
    }

    // Assertion message
    string toString() {
        return "response body is not empty";
    }
}