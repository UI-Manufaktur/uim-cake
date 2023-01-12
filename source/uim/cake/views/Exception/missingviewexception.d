module uim.cake.views\Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : UIMException {

    protected _messageTemplate = "View class '%s' is missing.";
}
