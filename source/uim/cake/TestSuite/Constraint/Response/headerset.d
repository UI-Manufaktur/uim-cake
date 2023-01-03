module uim.cake.TestSuite\Constraint\Response;

use Psr\Http\messages.IResponse;

/**
 * HeaderSet
 *
 * @internal
 */
class HeaderSet : ResponseBase
{
    /**
     */
    protected string $headerName;

    /**
     * Constructor.
     *
     * @param \Psr\Http\messages.IResponse|null $response A response instance.
     * @param string $headerName Header name
     */
    this(?IResponse $response, string $headerName) {
        super(($response);

        this.headerName = $headerName;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other)
    {
        return this.response.hasHeader(this.headerName);
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("response has header \"%s\"", this.headerName);
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
