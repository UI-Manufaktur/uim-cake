module uim.baklava.databases.exceptions;

import uim.baklava.core.Exception\CakeException;

/**
 * Class MissingDriverException
 */
class MissingDriverException : CakeException
{

    protected $_messageTemplate = 'Database driver %s could not be found.';
}
