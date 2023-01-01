module uim.cake.http.Exception;

use Throwable;

/**
 * Represents an HTTP 400 error.
 */
class BadRequestException : HttpException
{

    protected $_defaultCode = 400;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Bad Request" will be the message
     * @param int|null $code Status code, defaults to 400
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Bad Request";
        }
        super(($message, $code, $previous);
    }
}
