module uim.cake.TestSuite\Constraint\Response;

/**
 * Constraint for ensuring a header does not contain a value.
 *
 * @internal
 */
class HeaderNotContains : HeaderContains
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
        return sprintf(
            "is not in header '%s' (`%s`)",
            this.headerName,
            this.response.getHeaderLine(this.headerName)
        );
    }
}
