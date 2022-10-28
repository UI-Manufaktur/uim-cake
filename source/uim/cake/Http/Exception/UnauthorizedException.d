

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Exception;

use Throwable;

/**
 * Represents an HTTP 401 error.
 */
class UnauthorizedException : HttpException
{

    protected $_defaultCode = 401;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given 'Unauthorized' will be the message
     * @param int|null $code Status code, defaults to 401
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string myMessage = null, ?int $code = null, ?Throwable $previous = null)
    {
        if (empty(myMessage)) {
            myMessage = 'Unauthorized';
        }
        super.this(myMessage, $code, $previous);
    }
}
