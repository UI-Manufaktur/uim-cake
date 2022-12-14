module uim.cake.routings.Exception;

import uim.cake.core.exceptions.UIMException;
use Throwable;

/**
 * Exception raised when a URL cannot be reverse routed
 * or when a URL cannot be parsed.
 */
class MissingRouteException : UIMException {

    protected _messageTemplate = "A route matching '%s' could not be found.";

    /**
     * Message template to use when the requested method is included.
     */
    protected string _messageTemplateWithMethod = "A '%s' route matching '%s' could not be found.";

    /**
     * Constructor.
     *
     * @param array<string, mixed>|string $message Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error. Defaults to 404.
     * @param \Throwable|null $previous the previous exception.
     */
    this($message, Nullable!int $code = 404, ?Throwable $previous = null) {
        if (is_array($message)) {
            if (isset($message["message"])) {
                _messageTemplate = $message["message"];
            } elseif (isset($message["method"]) && $message["method"]) {
                _messageTemplate = _messageTemplateWithMethod;
            }
        }
        super(($message, $code, $previous);
    }
}
