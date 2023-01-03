module uim.cake.TestSuite\Constraint\Response;

/**
 * HeaderSet
 *
 * @internal
 */
class HeaderNotSet : HeaderSet
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other) {
        return super.matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("did not have header `%s`", this.headerName);
    }
}
