
module uim.cake.Console;

/**
 * An interface for shells that take a CommandCollection
 * during initialization.
 */
interface CommandCollectionAwareInterface
{
    /**
     * Set the command collection being used.
     *
     * @param uim.cake.consoles.CommandCollection $commands The commands to use.
     * @return void
     */
    function setCommandCollection(CommandCollection $commands): void;
}
