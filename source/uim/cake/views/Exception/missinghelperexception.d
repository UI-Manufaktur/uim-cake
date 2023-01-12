module uim.cake.views\Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : UIMException {

    protected _messageTemplate = "Helper class %s could not be found.";
}
