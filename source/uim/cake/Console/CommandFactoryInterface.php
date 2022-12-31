module uim.cake.Console;

/**
 * An interface for abstracting creation of command and shell instances.
 */
interface ICommandFactory
{
    /**
     * The factory method for creating Command and Shell instances.
     *
     * @param string $className Command/Shell class name.
     * @return uim.cake.consoles.Shell|uim.cake.consoles.ICommand
     */
    function create(string $className);
}
