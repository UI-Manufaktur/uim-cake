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
    bool matches($other)
    {
        return this._getBodyAsString() === $other;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'matches response body';
    }
}
