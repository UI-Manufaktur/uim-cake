module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyEmpty
 *
 * @internal
 */
class BodyEmpty : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        return empty(_getBodyAsString());
    }

    /**
     * Assertion message
     */
    string toString() {
        return "response body is empty";
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected function failureDescription($other): string
    {
        return this.toString();
    }
}
