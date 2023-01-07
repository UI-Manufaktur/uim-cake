module uim.cake.orm.Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Used when a behavior cannot be found.
 */
class MissingBehaviorException : UIMException {
    /**
     */
    protected string _messageTemplate = "Behavior class %s could not be found.";
}
