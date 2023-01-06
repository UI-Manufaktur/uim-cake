module uim.cake.https\Exception;

@safe:
import uim.cake;

// Represents an HTTP 400 error.
class BadRequestException : HttpException {

    protected _defaultCode = 400;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given "Bad Request" will be the message
     * @param int|null $code Status code, defaults to 400
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = "Bad Request";
        }
        super.this(myMessage, $code, $previous);
    }
}
