module uim.cake.console;

/**
 * An interface for shells that take a CommandCollection
 * during initialization.
 */
interface ICommandCollectionAware
{
    /**
     * Set the command collection being used.
     *
     * @param \Cake\Console\CommandCollection $commands The commands to use.
     * @return void
     */
    void setCommandCollection(CommandCollection $commands);
}
