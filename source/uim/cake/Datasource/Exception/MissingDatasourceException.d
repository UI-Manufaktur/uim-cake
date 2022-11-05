module uim.baklava.Datasource\Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Used when a datasource cannot be found.
 */
class MissingDatasourceException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Datasource class %s could not be found. %s';
}
