module uim.baklava.TestSuite\Constraint\Response;

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
     */
    bool matches($other) {
        return super.matches($other) === false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'response body is not empty';
    }
}
