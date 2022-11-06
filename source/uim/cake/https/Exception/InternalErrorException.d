

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https\Exception;

use Throwable;

/**
 * Represents an HTTP 500 error.
 */
class InternalErrorException : HttpException
{
    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given 'Internal Server Error' will be the message
     * @param int|null $code Status code, defaults to 500
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = 'Internal Server Error';
        }
        super.this(myMessage, $code, $previous);
    }
}
