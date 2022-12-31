module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsRegExp
 *
 * @internal
 */
class ContentsRegExp : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return preg_match($other, this.contents) > 0;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("PCRE pattern found in %s", this.output);
    }

    /**
     * @param mixed $other Expected
     */
    string failureDescription($other) {
        return "`" . $other . "` " . this.toString();
    }
}
