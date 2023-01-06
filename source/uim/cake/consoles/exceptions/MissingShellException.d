module uim.cake.consoles.Exception;

/**
 * Used when a shell cannot be found.
 */
class MissingShellException : ConsoleException
{
    /**
     */
    protected string _messageTemplate = "Shell class for "%s" could not be found."
        ~ " If you are trying to use a plugin shell, that was loaded via this.addPlugin(),"
        ~ " you may need to update bin/cake.php to match https://github.com/cakephp/app/tree/master/bin/cake.php";
}
