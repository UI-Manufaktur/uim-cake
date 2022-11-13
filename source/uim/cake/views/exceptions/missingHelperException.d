module uim.cakeews.exceptions;

import uim.cake.core.exceptions\CakeException;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Helper class %s could not be found.';
}
