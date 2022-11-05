module uim.cake.views.exceptions;

import uim.cake.core.Exception\CakeException;

/**
 * Used when a view class file cannot be found.
 */
class MissingViewException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'View class "%s" is missing.';
}
