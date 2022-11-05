module uim.baklava.views.exceptions;

import uim.baklava.core.exceptions\CakeException;

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
