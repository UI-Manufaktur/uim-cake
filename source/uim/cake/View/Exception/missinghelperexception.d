module uim.cake.View\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : CakeException
{

    protected _messageTemplate = "Helper class %s could not be found.";
}
