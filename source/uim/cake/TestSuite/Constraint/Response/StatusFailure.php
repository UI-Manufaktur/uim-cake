module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusFailure
 *
 * @internal
 */
class StatusFailure : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [500, 505];

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("%d is between 500 and 505", this.response.getStatusCode());
    }
}
