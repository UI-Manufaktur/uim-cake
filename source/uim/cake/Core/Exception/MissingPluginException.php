module uim.cake.core.Exception;

/**
 * Exception raised when a plugin could not be found
 */
class MissingPluginException : CakeException
{

    protected $_messageTemplate = "Plugin %s could not be found.";
}
