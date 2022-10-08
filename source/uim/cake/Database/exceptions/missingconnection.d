module uim.cake.database.exceptions;

import uim.cake.core.Exception\CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{

    protected $_messageTemplate = 'Connection to %s could not be established: %s';
}
