module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusSuccess
 *
 * @internal
 */
class StatusSuccess : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [200, 308];

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("%d is between 200 and 308", this.response.getStatusCode());
    }
}
