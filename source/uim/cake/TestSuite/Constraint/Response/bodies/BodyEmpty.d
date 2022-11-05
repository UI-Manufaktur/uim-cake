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
     */
    bool matches($other)
    {
        return empty(this._getBodyAsString());
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'response body is empty';
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected auto failureDescription($other): string
    {
        return this.toString();
    }
}
