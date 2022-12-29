

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.http.Exception;

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
     * @param string|null $message If no message is given "Unauthorized" will be the message
     * @param int|null $code Status code, defaults to 401
     * @param \Throwable|null $previous The previous exception.
     */
    public this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Unauthorized";
        }
        super(($message, $code, $previous);
    }
}
