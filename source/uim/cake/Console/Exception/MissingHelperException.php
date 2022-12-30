module uim.cake.consoles.Exception;

/**
 * Used when a Helper cannot be found.
 */
class MissingHelperException : ConsoleException
{
    /**
     */
    protected string $_messageTemplate = "Helper class %s could not be found.";
}
