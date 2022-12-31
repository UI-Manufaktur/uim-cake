module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyRegExp
 *
 * @internal
 */
class BodyRegExp : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected pattern
     * @return bool
     */
    function matches($other): bool
    {
        return preg_match($other, _getBodyAsString()) > 0;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "PCRE pattern found in response body";
    }

    /**
     * @param mixed $other Expected
     */
    string failureDescription($other): string
    {
        return "`" . $other . "`" . " " . this.toString();
    }
}
