module uim.cake.View\Exception;

import uim.cake.core.Exception\CakeException;

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
