module uim.cake.consoles.Exception;

/**
 * Used when a shell method cannot be found.
 */
class MissingShellMethodException : ConsoleException
{
    /**
     */
    protected string $_messageTemplate = "Unknown command %1\$s %2\$s.\nFor usage try `cake %1\$s --help`";
}
