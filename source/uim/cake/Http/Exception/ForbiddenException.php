

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
module uim.cake.https.Exception;

use Throwable;

/**
 * Represents an HTTP 403 error.
 */
class ForbiddenException : HttpException
{

    protected $_defaultCode = 403;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Forbidden" will be the message
     * @param int|null $code Status code, defaults to 403
     * @param \Throwable|null $previous The previous exception.
     */
    public this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Forbidden";
        }
        super(($message, $code, $previous);
    }
}
