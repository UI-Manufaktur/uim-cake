module uim.cake.consoles.Exception;

/**
 * Used when a Task cannot be found.
 */
class MissingTaskException : ConsoleException
{
    /**
     */
    protected string _messageTemplate = "Task class %s could not be found.";
}
