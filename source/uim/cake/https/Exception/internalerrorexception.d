module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 500 error.
 */
class InternalErrorException : HttpException {
    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Internal Server Error" will be the message
     * @param int|null $code Status code, defaults to 500
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Internal Server Error";
        }
        super(($message, $code, $previous);
    }
}
