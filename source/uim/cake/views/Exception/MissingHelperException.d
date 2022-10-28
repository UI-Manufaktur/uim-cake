module uim.cake.views\Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : CakeException
{

    protected $_messageTemplate = 'Helper class %s could not be found.';
}
