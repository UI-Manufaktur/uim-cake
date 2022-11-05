module uim.baklava.datasources\Exception;

import uim.baklava.core.exceptions\CakeException;

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
