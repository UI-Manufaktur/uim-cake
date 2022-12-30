
module uim.cake.datasources.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a model cannot be found.
 */
class MissingModelException : CakeException
{
    /**
     */
    protected string $_messageTemplate = "Model class "%s" of type "%s" could not be found.";
}
