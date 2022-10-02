

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.3.1
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Routing\Exception;

import uim.cake.core.Exception\CakeException;
use Throwable;

/**
 * Exception raised when a route names used twice.
 */
class DuplicateNamedRouteException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'A route named "%s" has already been connected to "%s".';

    /**
     * Constructor.
     *
     * @param array<string, mixed>|string myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()'d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error. Defaults to 404.
     * @param \Throwable|null $previous the previous exception.
     */
    this(myMessage, ?int $code = 404, ?Throwable $previous = null)
    {
        if (is_array(myMessage) && isset(myMessage['message'])) {
            this._messageTemplate = myMessage['message'];
        }
        super.this(myMessage, $code, $previous);
    }
}
