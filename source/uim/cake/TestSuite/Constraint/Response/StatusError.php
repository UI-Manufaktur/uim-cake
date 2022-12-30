module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusError
 *
 * @internal
 */
class StatusError : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [400, 429];

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("%d is between 400 and 429", this.response.getStatusCode());
    }
}
