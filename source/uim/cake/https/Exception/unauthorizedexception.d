module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 401 error.
 */
class UnauthorizedException : HttpException {

    protected _defaultCode = 401;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Unauthorized" will be the message
     * @param int|null $code Status code, defaults to 401
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Unauthorized";
        }
        super(($message, $code, $previous);
    }
}
