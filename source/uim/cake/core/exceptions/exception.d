module uim.cake.core.exceptions.exception;

@safe:
import uim.cake;

/**
 * Base class that all UIM Exceptions extend.
 *
 * @method int getCode() Gets the Exception code.
 */
class CakeException : RuntimeException
{
    /**
     * Array of attributes that are passed in from the constructor, and
     * made available in the view when a development error is displayed.
     *
     * @var array
     */
    protected $_attributes = [];

    /**
     * Template string that has attributes sprintf()"ed into it.
     */
    protected string $_messageTemplate = "";

    /**
     * Array of headers to be passed to {@link \Cake\Http\Response::withHeader()}
     *
     * @var array|null
     */
    protected $_responseHeaders;

    /**
     * Default exception code
     *
     * @var int
     */
    protected $_defaultCode = 0;

    /**
     * Constructor.
     *
     * Allows you to create exceptions that are treated as framework errors and disabled
     * when debug mode is off.
     *
     * @param array|string myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The error code
     * @param \Throwable|null $previous the previous exception.
     */
    this(myMessage = "", Nullable!int $code = null, ?Throwable $previous = null) {
        if (is_array(myMessage)) {
            this._attributes = myMessage;
            myMessage = vsprintf(this._messageTemplate, myMessage);
        }
        super.this(myMessage, $code ?? this._defaultCode, $previous);
    }

    // Get the passed in attributes
    array getAttributes() {
        return this._attributes;
    }

    /**
     * Get/set the response header to be used
     *
     * See also {@link \Cake\Http\Response::withHeader()}
     *
     * @param array|string|null $header A single header string or an associative
     *   array of "header name":"header value"
     * @param string|null myValue The header value.
     * @return array|null
     * @deprecated 4.2.0 Use `HttpException::setHeaders()` instead. Response headers
     *   should be set for HttpException only.
     */
    function responseHeader($header = null, myValue = null): ?array
    {
        if ($header == null) {
            return this._responseHeaders;
        }

        deprecationWarning(
            "Setting HTTP response headers from Exception directly is deprecated. " .
            "If your exceptions extend Exception, they must now extend HttpException. " .
            "You should only set HTTP headers on HttpException instances via the `setHeaders()` method."
        );
        if (is_array($header)) {
            return this._responseHeaders = $header;
        }

        return this._responseHeaders = [$header: myValue];
    }
}

// phpcs:disable
class_exists("Cake\Core\Exception\Exception");
// phpcs:enable
