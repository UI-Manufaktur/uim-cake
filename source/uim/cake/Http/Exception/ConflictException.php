

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.1.7
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.http.Exception;

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
     * @param string|null $message If no message is given "Conflict" will be the message
     * @param int|null $code Status code, defaults to 409
     * @param \Throwable|null $previous The previous exception.
     */
    public this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Conflict";
        }
        super(($message, $code, $previous);
    }
}
