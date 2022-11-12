module uim.cakensole\Exception;

/**
 * Used when a shell method cannot be found.
 */
class MissingShellMethodException : ConsoleException
{
    /**
     * @var string
     */
    protected $_messageTemplate = "Unknown command %1\$s %2\$s.\nFor usage try `cake %1\$s --help`";
}
