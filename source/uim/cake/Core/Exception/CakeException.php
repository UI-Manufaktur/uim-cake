

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.cores.Exception;

use RuntimeException;
use Throwable;

/**
 * Base class that all CakePHP Exceptions extend.
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
     *
     * @var string
     */
    protected $_messageTemplate = "";

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
     * @param array|string $message Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The error code
     * @param \Throwable|null $previous the previous exception.
     */
    public this($message = "", ?int $code = null, ?Throwable $previous = null) {
        if (is_array($message)) {
            _attributes = $message;
            $message = vsprintf(_messageTemplate, $message);
        }
        super(($message, $code ?? _defaultCode, $previous);
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     */
    function getAttributes(): array
    {
        return _attributes;
    }

    /**
     * Get/set the response header to be used
     *
     * See also {@link \Cake\Http\Response::withHeader()}
     *
     * @param array|string|null $header A single header string or an associative
     *   array of "header name": "header value"
     * @param string|null $value The header value.
     * @return array|null
     * @deprecated 4.2.0 Use `HttpException::setHeaders()` instead. Response headers
     *   should be set for HttpException only.
     */
    function responseHeader($header = null, $value = null): ?array
    {
        if ($header == null) {
            return _responseHeaders;
        }

        deprecationWarning(
            "Setting HTTP response headers from Exception directly is deprecated. " .
            "If your exceptions extend Exception, they must now extend HttpException. " .
            "You should only set HTTP headers on HttpException instances via the `setHeaders()` method."
        );
        if (is_array($header)) {
            return _responseHeaders = $header;
        }

        return _responseHeaders = [$header: $value];
    }
}

// phpcs:disable
class_exists("Cake\Core\Exception\Exception");
// phpcs:enable
