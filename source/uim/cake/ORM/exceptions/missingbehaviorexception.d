module uim.cake.orm.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a behavior cannot be found.
 */
class MissingBehaviorException : CakeException
{
    /**
     */
    protected string $_messageTemplate = "Behavior class %s could not be found.";
}
