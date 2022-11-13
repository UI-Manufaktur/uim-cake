module uim.cakeews\Exception;

import uim.cakere.exceptions\CakeException;

/**
 * Used when a cell class file cannot be found.
 */
class MissingCellException : CakeException
{

    protected $_messageTemplate = "Cell class %s is missing.";
}
