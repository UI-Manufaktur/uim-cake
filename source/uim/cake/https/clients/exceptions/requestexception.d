module uim.cake.http.clients\Exception;

@safe:
import uim.cake;

/**
 * Exception for when a request failed.
 *
 * Examples:
 *
 *   - Request is invalid (e.g. method is missing)
 *   - Runtime request errors (e.g. the body stream is not seekable)
 */
class RequestException : RuntimeException : RequestExceptionInterface
{
    /**
     * @var \Psr\Http\messages.RequestInterface
     */
    protected myRequest;

    /**
     * Constructor.
     *
     * @param string myMessage Exeception message.
     * @param \Psr\Http\messages.RequestInterface myRequest Request instance.
     * @param \Throwable|null $previous Previous Exception
     */
    this(string myMessage, RequestInterface myRequest, ?Throwable $previous = null) {
        this.request = myRequest;
        super.this(myMessage, 0, $previous);
    }

    /**
     * Returns the request.
     *
     * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
     *
     * @return \Psr\Http\messages.RequestInterface
     */
    auto getRequest(): RequestInterface
    {
        return this.request;
    }
}
