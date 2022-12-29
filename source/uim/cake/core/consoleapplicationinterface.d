module uim.cake.core;

import uim.cake.console.commandCollection;

/**
 * An interface defining the methods that the
 * console runner depend on.
 */
interface IConsoleApplication
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     *
     */
    void bootstrap();

    /**
     * Define the console commands for an application.
     *
     * @param uim.cake.Console\CommandCollection $commands The CommandCollection to add commands into.
     * @return uim.cake.Console\CommandCollection The updated collection.
     */
    CommandCollection console(CommandCollection $commands);
}
