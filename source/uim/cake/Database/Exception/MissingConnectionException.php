module uim.cake.database.Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Class MissingConnectionException
 */
class MissingConnectionException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Connection to %s could not be established: %s';
}
