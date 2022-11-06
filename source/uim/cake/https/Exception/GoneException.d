

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.1.7
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.caketps\Exception;

use Throwable;

/**
 * Represents an HTTP 410 error.
 */
class GoneException : HttpException
{

    protected $_defaultCode = 410;

    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given 'Gone' will be the message
     * @param int|null $code Status code, defaults to 410
     * @param \Throwable|null $previous The previous exception.
     */
    this(Nullable!string myMessage = null, Nullable!int $code = null, ?Throwable $previous = null) {
        if (empty(myMessage)) {
            myMessage = 'Gone';
        }
        super.this(myMessage, $code, $previous);
    }
}
