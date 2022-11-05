

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Routing\Exception;

import uim.baklava.core.exceptions\CakeException;
use Throwable;

/**
 * Exception raised when a URL cannot be reverse routed
 * or when a URL cannot be parsed.
 */
class MissingRouteException : CakeException
{

    protected $_messageTemplate = 'A route matching "%s" could not be found.';

    /**
     * Message template to use when the requested method is included.
     *
     * @var string
     */
    protected $_messageTemplateWithMethod = 'A "%s" route matching "%s" could not be found.';

    /**
     * Constructor.
     *
     * @param array<string, mixed>|string myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()'d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error. Defaults to 404.
     * @param \Throwable|null $previous the previous exception.
     */
    this(myMessage, Nullable!int $code = 404, ?Throwable $previous = null) {
        if (is_array(myMessage)) {
            if (isset(myMessage['message'])) {
                this._messageTemplate = myMessage['message'];
            } elseif (isset(myMessage['method']) && myMessage['method']) {
                this._messageTemplate = this._messageTemplateWithMethod;
            }
        }
        super.this(myMessage, $code, $previous);
    }
}
