module uim.baklava.views.exceptions;

import uim.baklava.core.Exception\CakeException;

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
