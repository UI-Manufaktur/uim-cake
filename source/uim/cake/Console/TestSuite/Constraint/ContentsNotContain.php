module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsNotContain
 *
 * @internal
 */
class ContentsNotContain : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    bool matches($other) {
        return mb_strpos(this.contents, $other) == false;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("is not in %s", this.output);
    }
}
