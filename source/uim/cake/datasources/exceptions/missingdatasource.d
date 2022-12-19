module uim.cake.datasources.exceptions;

@safe:
import uim.cake;

/**
 * Used when a datasource cannot be found.
 */
class MissingDatasourceException : CakeException
{
    /**
     * @var string
     */
    protected _messageTemplate = "Datasource class %s could not be found. %s";
}
