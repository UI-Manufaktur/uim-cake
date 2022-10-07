

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.7
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Exception;

use Throwable;

/**
 * Represents an HTTP 409 error.
 */
class ConflictException : HttpException
{

    protected $_defaultCode = 409;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given 'Conflict' will be the message
     * @param int|null $code Status code, defaults to 409
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string myMessage = null, ?int $code = null, ?Throwable $previous = null)
    {
        if (empty(myMessage)) {
            myMessage = 'Conflict';
        }
        super.this(myMessage, $code, $previous);
    }
}
