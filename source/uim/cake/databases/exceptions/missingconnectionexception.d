module uim.cake.databases.exceptions;

import uim.cake.core.exceptions.CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{

    protected $_messageTemplate = "Connection to %s could not be established: %s";
}
