module uim.cake.View\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : CakeException
{

    protected _messageTemplate = "Cell class %s is missing.";
}
