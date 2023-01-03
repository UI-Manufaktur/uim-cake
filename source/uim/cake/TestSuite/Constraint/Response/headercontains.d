module uim.cake.TestSuite\Constraint\Response;

/**
 * HeaderContains
 *
 * @internal
 */
class HeaderContains : HeaderEquals
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other) {
        return mb_strpos(this.response.getHeaderLine(this.headerName), $other) != false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf(
            "is in header \"%s\" (`%s`)",
            this.headerName,
            this.response.getHeaderLine(this.headerName)
        );
    }
}
