module uim.cake.View\Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : UIMException {

    protected _messageTemplate = "Cell class %s is missing.";
}
