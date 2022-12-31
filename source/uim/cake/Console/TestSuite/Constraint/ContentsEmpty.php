module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsEmpty
 *
 * @internal
 */
class ContentsEmpty : ContentsBase
{
    /**
     * Checks if contents are empty
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return this.contents == "";
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("%s is empty", this.output);
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other): string
    {
        return this.toString();
    }
}
