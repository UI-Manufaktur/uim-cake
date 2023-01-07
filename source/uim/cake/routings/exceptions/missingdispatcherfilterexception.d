module uim.cake.routings.Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Exception raised when a Dispatcher filter could not be found
 */
class MissingDispatcherFilterException : UIMException {

    protected _messageTemplate = "Dispatcher filter %s could not be found.";
}
