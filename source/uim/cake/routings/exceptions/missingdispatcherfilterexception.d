module uim.cake.routings.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Exception raised when a Dispatcher filter could not be found
 */
class MissingDispatcherFilterException : CakeException
{

    protected _messageTemplate = "Dispatcher filter %s could not be found.";
}
