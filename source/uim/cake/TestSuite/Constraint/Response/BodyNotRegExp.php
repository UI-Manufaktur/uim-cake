module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyNotRegExp
 *
 * @internal
 */
class BodyNotRegExp : BodyRegExp
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected pattern
     * @return bool
     */
    function matches($other): bool
    {
        return parent::matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "PCRE pattern not found in response body";
    }
}
