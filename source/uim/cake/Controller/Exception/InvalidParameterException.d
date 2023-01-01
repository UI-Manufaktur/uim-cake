

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         4.3.0
  */module uim.cake.controllers.Exception;

import uim.cake.core.exceptions.CakeException;
use Throwable;

/**
 * Used when a passed parameter or action parameter type declaration is missing or invalid.
 */
class InvalidParameterException : CakeException
{
    /**
     * @var array<string, string>
     */
    protected $templates = [
        "failed_coercion": "Unable to coerce "%s" to `%s` for `%s` in action %s::%s().",
        "missing_dependency": "Failed to inject dependency from service container for parameter `%s` " ~
            "with type `%s` in action %s::%s().",
        "missing_parameter": "Missing passed parameter for `%s` in action %s::%s().",
        "unsupported_type": "Type declaration for `%s` in action %s::%s() is unsupported.",
    ];

    /**
     * Switches message template based on `template` key in message array.
     *
     * @param string|array $message Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The error code
     * @param \Throwable|null $previous the previous exception.
     */
    this($message = "", ?int $code = null, ?Throwable $previous = null) {
        if (is_array($message)) {
            _messageTemplate = this.templates[$message["template"]] ?? "";
            unset($message["template"]);
        }
        super(($message, $code, $previous);
    }
}
