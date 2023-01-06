module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 403 error.
 */
class ForbiddenException : HttpException
{

    protected _defaultCode = 403;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Forbidden" will be the message
     * @param int|null $code Status code, defaults to 403
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Forbidden";
        }
        super(($message, $code, $previous);
    }
}
