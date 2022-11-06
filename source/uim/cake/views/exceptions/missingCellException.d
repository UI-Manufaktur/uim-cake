module uim.cakeews.exceptions;

import uim.cakere.exceptions\CakeException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Cell class %s is missing.';
}