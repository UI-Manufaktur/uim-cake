module uim.cake.TestSuite\Constraint\Response;

/**
 * StatusCodeBase
 *
 * @internal
 */
abstract class StatusCodeBase : ResponseBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code;

    /**
     * Check assertion
     *
     * @param array<int, int>|int $other Array of min/max status codes, or a single code
     * @return bool
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    bool matches($other)
    {
        if (!$other) {
            $other = this.code;
        }

        if (is_array($other)) {
            return this.statusCodeBetween($other[0], $other[1]);
        }

        return this.response.getStatusCode() == $other;
    }

    /**
     * Helper for checking status codes
     *
     * @param int $min Min status code (inclusive)
     * @param int $max Max status code (inclusive)
     */
    protected bool statusCodeBetween(int $min, int $max)
    {
        return this.response.getStatusCode() >= $min && this.response.getStatusCode() <= $max;
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other): string
    {
        /** @psalm-suppress InternalMethod */
        return this.toString();
    }
}
