module uim.baklava.Datasource\Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Exception class to be thrown when a datasource configuration is not found
 */
class MissingDatasourceConfigException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'The datasource configuration "%s" was not found.';
}
