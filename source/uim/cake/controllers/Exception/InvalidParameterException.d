module uim.cake.controllers\Exception;

import uim.cake.core.exceptions\CakeException;
use Throwable;

/**
 * Used when a passed parameter or action parameter type declaration is missing or invalid.
 */
class InvalidParameterException : CakeException
{
    /**
     * @var array<string, string>
     */
    protected myTemplates = [
        "failed_coercion" => "Unable to coerce "%s" to `%s` for `%s` in action %s::%s().",
        "missing_dependency" => "Failed to inject dependency from service container for `%s` in action %s::%s().",
        "missing_parameter" => "Missing passed parameter for `%s` in action %s::%s().",
        "unsupported_type" => "Type declaration for `%s` in action %s::%s() is unsupported.",
    ];

    /**
     * Switches message template based on `template` key in message array.
     *
     * @param string|array myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The error code
     * @param \Throwable|null $previous the previous exception.
     */
    this(myMessage = "", Nullable!int $code = null, ?Throwable $previous = null) {
        if (is_array(myMessage)) {
            this._messageTemplate = this.templates[myMessage["template"]] ?? "";
            unset(myMessage["template"]);
        }
        super.this(myMessage, $code, $previous);
    }
}
