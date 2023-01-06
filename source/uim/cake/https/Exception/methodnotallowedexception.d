module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 405 error.
 */
class MethodNotAllowedException : HttpException {

    protected _defaultCode = 405;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Method Not Allowed" will be the message
     * @param int|null $code Status code, defaults to 405
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Method Not Allowed";
        }
        super(($message, $code, $previous);
    }
}
