module uim.cake.datasources.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Exception class to be thrown when a datasource configuration is not found
 */
class MissingDatasourceConfigException : CakeException
{
    /**
     */
    protected string $_messageTemplate = "The datasource configuration "%s" was not found.";
}
