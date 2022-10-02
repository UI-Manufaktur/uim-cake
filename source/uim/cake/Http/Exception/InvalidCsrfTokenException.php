

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Exception;

use Throwable;

/**
 * Represents an HTTP 403 error caused by an invalid CSRF token
 */
class InvalidCsrfTokenException : HttpException
{
    /**
     * @inheritDoc
     */
    protected $_defaultCode = 403;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given 'Invalid CSRF Token' will be the message
     * @param int|null $code Status code, defaults to 403
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string myMessage = null, ?int $code = null, ?Throwable $previous = null)
    {
        if (empty(myMessage)) {
            myMessage = 'Invalid CSRF Token';
        }
        super.this(myMessage, $code, $previous);
    }
}
