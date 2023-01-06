module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 404 error.
 */
class NotFoundException : HttpException
{

    protected _defaultCode = 404;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Not Found" will be the message
     * @param int|null $code Status code, defaults to 404
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Not Found";
        }
        super(($message, $code, $previous);
    }
}
