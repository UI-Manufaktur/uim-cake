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
     * @param string myAlias The alias name you want to get.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     * @return \Cake\Datasource\IRepository
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    auto get(string myAlias, array myOptions = []);

    /**
     * Set a repository instance.
     *
     * @param string myAlias The alias to set.
     * @param \Cake\Datasource\IRepository myRepository The repository to set.
     * @return \Cake\Datasource\IRepository
     */
    auto set(string myAlias, IRepository myRepository);

    /**
     * Check to see if an instance exists in the registry.
     *
     * @param string myAlias The alias to check for.
     */
    bool exists(string myAlias);

    /**
     * Removes an repository instance from the registry.
     *
     * @param string myAlias The alias to remove.
     * @return void
     */
    void remove(string myAlias);

    // Clears the registry of configuration and instances.
    void clear();
}
