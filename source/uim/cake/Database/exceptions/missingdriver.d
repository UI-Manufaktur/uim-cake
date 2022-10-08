module uim.cake.databases.exceptions;

import uim.cake.core.Exception\CakeException;

/**
 * Class MissingDriverException
 */
class MissingDriverException : CakeException
{

    protected $_messageTemplate = 'Database driver %s could not be found.';
}
