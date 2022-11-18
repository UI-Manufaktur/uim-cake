module uim.cake.console.commands.collectionawareinterface;

@safe:
import uim.cake;

/**
 * An interface for shells that take a CommandCollection
 * during initialization.
 */
interface ICommandCollectionAware {
    // Set the command collection being used.
    void setCommandCollection(CommandCollection newCommands);
}
