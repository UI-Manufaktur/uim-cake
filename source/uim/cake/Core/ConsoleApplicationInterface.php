

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright 2005-2011, Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */
module uim.cake.Core;

import uim.cake.consoles.CommandCollection;

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
     */
    void bootstrap(): void;

    /**
     * Define the console commands for an application.
     *
     * @param uim.cake.consoles.CommandCollection $commands The CommandCollection to add commands into.
     * @return uim.cake.consoles.CommandCollection The updated collection.
     */
    function console(CommandCollection $commands): CommandCollection;
}
