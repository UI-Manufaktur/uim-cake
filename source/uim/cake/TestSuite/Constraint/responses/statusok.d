module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusOk
 *
 * @internal
 */
class StatusOk : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [200, 204];

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("%d is between 200 and 204", this.response.getStatusCode());
    }
}
