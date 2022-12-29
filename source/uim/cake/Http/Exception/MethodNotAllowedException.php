

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
module uim.cake.Http\Exception;

use Throwable;

/**
 * Represents an HTTP 405 error.
 */
class MethodNotAllowedException : HttpException
{

    protected $_defaultCode = 405;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Method Not Allowed" will be the message
     * @param int|null $code Status code, defaults to 405
     * @param \Throwable|null $previous The previous exception.
     */
    public this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Method Not Allowed";
        }
        super(($message, $code, $previous);
    }
}
