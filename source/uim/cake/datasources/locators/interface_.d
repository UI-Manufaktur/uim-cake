/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.datasources\Locator;

import uim.cake.datasources\IRepository;

/**
 * Registries for repository objects should implement this interface.
 */
interface ILocator
{
    /**
     * Get a repository instance from the registry.
     *
     * @param string $alias The alias name you want to get.
     * @param array<string, mixed> $options The options you want to build the table with.
     * @return uim.cake.Datasource\IRepository
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    function get(string $alias, STRINGAA someOptions = []);

    /**
     * Set a repository instance.
     *
     * @param string $alias The alias to set.
     * @param uim.cake.Datasource\IRepository $repository The repository to set.
     * @return uim.cake.Datasource\IRepository
     */
    function set(string $alias, IRepository $repository);

    /**
     * Check to see if an instance exists in the registry.
     *
     * @param string $alias The alias to check for.
     */
    bool exists(string $alias);

    /**
     * Removes an repository instance from the registry.
     *
     * @param string $alias The alias to remove.
     */
    void remove(string $alias);

    /**
     * Clears the registry of configuration and instances.
     */
    void clear();
}
