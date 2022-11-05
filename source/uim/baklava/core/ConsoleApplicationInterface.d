module uim.baklava.core;

import uim.baklava.console.commandCollection;

/**
 * An interface defining the methods that the
 * console runner depend on.
 */
interface ConsoleApplicationInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * Override this method to add additional bootstrap logic for your application.
     *
     * @return void
     */
    function bootstrap(): void;

    /**
     * Define the console commands for an application.
     *
     * @param \Cake\Console\CommandCollection $commands The CommandCollection to add commands into.
     * @return \Cake\Console\CommandCollection The updated collection.
     */
    function console(CommandCollection $commands): CommandCollection;
}
