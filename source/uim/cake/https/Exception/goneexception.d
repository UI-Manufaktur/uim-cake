

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
 * Represents an HTTP 410 error.
 */
class GoneException : HttpException {

    protected _defaultCode = 410;

    /**
     * Constructor
     *
     * @param string|null $message If no message is given "Gone" will be the message
     * @param int|null $code Status code, defaults to 410
     * @param \Throwable|null $previous The previous exception.
     */
    this(?string $message = null, ?int $code = null, ?Throwable $previous = null) {
        if (empty($message)) {
            $message = "Gone";
        }
        super(($message, $code, $previous);
    }
}
