module uim.cake.views\Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : CakeException
{

    protected $_messageTemplate = 'View class "%s" is missing.';
}
