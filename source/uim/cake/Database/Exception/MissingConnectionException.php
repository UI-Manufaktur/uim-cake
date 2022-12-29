


 *



  */
module uim.cake.databases.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{

    protected $_messageTemplate = "Connection to %s could not be established: %s";
}
