module uim.cake.TestSuite\Constraint\Response;

use Psr\Http\messages.IResponse;

/**
 * HeaderEquals
 *
 * @internal
 */
class HeaderEquals : ResponseBase
{
    /**
     */
    protected string $headerName;

    /**
     * Constructor.
     *
     * @param \Psr\Http\messages.IResponse $response A response instance.
     * @param string $headerName Header name
     */
    this(IResponse $response, string $headerName) {
        super(($response);

        this.headerName = $headerName;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other) {
        return this.response.getHeaderLine(this.headerName) == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        $responseHeader = this.response.getHeaderLine(this.headerName);

        return sprintf("equals content in header \"%s\" (`%s`)", this.headerName, $responseHeader);
    }
}
