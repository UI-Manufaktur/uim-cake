module uim.baklava.databases.exceptions;

import uim.baklava.core.Exception\CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{

    protected $_messageTemplate = 'Connection to %s could not be established: %s';
}
