module Cake\Core;

use Cake\Console\CommandCollection;

/**
 * An interface defining the methods that the
 * console runner depend on.
 */
interface ConsoleApplicationInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     * Override this method to add additional bootstrap logic for your application.
     */
    public void bootstrap();

    /**
     * Define the console commands for an application.
     *
     * @param \Cake\Console\CommandCollection $commands The CommandCollection to add commands into.
     * @return \Cake\Console\CommandCollection The updated collection.
     */
    public CommandCollection console(CommandCollection $commands);
}
