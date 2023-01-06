

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.1.7
  */module uim.cake.http.exceptions;

use Throwable;

/**
 * Represents an HTTP 503 error.
 */
class ServiceUnavailableException : HttpException {

    protected _defaultCode = 503;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Service Unavailable" will be the message
     * @param int|null $code Status code, defaults to 503
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Service Unavailable";
        }
        super(($message, $code, $previous);
    }
}
