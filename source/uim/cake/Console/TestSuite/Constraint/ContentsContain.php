module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsContain
 *
 * @internal
 */
class ContentsContain : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return mb_strpos(this.contents, $other) != false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("is in %s," ~ PHP_EOL ~ "actual result:" ~ PHP_EOL, this.output) . this.contents;
    }
}
