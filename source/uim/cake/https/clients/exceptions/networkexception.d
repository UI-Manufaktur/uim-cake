module uim.cake.http.clients\Exception;

@safe:
import uim.cake;

use Psr\Http\Client\NetworkExceptionInterface;
use Psr\Http\messages.RequestInterface;
use RuntimeException;
use Throwable;

/**
 * Thrown when the request cannot be completed because of network issues.
 *
 * There is no response object as this exception is thrown when no response has been received.
 *
 * Example: the target host name can not be resolved or the connection failed.
 */
class NetworkException : RuntimeException : NetworkExceptionInterface
{
    /**
     * @var \Psr\Http\messages.RequestInterface
     */
    protected $request;

    /**
     * Constructor.
     *
     * @param string $message Exeception message.
     * @param \Psr\Http\messages.RequestInterface $request Request instance.
     * @param \Throwable|null $previous Previous Exception
     */
    this(string $message, RequestInterface $request, ?Throwable $previous = null) {
        this.request = $request;
        super(($message, 0, $previous);
    }

    /**
     * Returns the request.
     *
     * The request object MAY be a different object from the one passed to ClientInterface::sendRequest()
     *
     * @return \Psr\Http\messages.RequestInterface
     */
    function getRequest(): RequestInterface
    {
        return this.request;
    }
}
