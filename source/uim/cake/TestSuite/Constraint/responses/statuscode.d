module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusCode
 *
 * @internal
 */
class StatusCode : StatusCodeBase
{
    /**
     * Assertion message
     */
    string toString() {
        return sprintf("matches response status code `%d`", this.response.getStatusCode());
    }

    /**
     * Failure description
     *
     * @param mixed $other Expected code
     */
    string failureDescription($other) {
        return "`" ~ $other ~ "` " ~ this.toString();
    }
}
