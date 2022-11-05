module uim.baklava.views\Exception;

import uim.baklava.core.exceptions\CakeException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : CakeException
{

    protected $_messageTemplate = 'Cell class %s is missing.';
}
