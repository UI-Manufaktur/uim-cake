

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.3.1
  */
module uim.cake.routings.Exception;

import uim.cake.core.exceptions.CakeException;
use Throwable;

/**
 * Exception raised when a route names used twice.
 */
class DuplicateNamedRouteException : CakeException
{

    protected $_messageTemplate = "A route named "%s" has already been connected to "%s".";

    /**
     * Constructor.
     *
     * @param array<string, mixed>|string $message Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error. Defaults to 404.
     * @param \Throwable|null $previous the previous exception.
     */
    this($message, ?int $code = 404, ?Throwable $previous = null) {
        if (is_array($message) && isset($message["message"])) {
            _messageTemplate = $message["message"];
        }
        super(($message, $code, $previous);
    }
}
