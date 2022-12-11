module uim.cake.https\Exception;

@safe:
import uim.cake;

/**
 * Represents an HTTP 409 error.
 */
class ConflictException : HttpException
{

    protected $_defaultCode = 409;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given "Conflict" will be the message
     * @param int|null $code Status code, defaults to 409
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = "Conflict";
        }
        super.this(myMessage, $code, $previous);
    }
}
