module uim.cake.controllers.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a component cannot be found.
 */
class MissingComponentException : CakeException
{

    protected $_messageTemplate = "Component class %s could not be found.";
}
