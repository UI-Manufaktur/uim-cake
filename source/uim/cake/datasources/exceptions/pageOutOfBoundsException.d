module uim.cake.datasources\Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : CakeException
{

    protected _messageTemplate = "Page number %s could not be found.";
}
