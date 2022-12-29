


 *


 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Datasource\Locator;

import uim.cake.Datasource\RepositoryInterface;

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
     * @return \Cake\Datasource\RepositoryInterface
     * @throws \RuntimeException When trying to get alias for which instance
     *   has already been created with different options.
     */
    function get(string $alias, array $options = []);

    /**
     * Set a repository instance.
     *
     * @param string $alias The alias to set.
     * @param \Cake\Datasource\RepositoryInterface $repository The repository to set.
     * @return \Cake\Datasource\RepositoryInterface
     */
    function set(string $alias, RepositoryInterface $repository);

    /**
     * Check to see if an instance exists in the registry.
     *
     * @param string $alias The alias to check for.
     * @return bool
     */
    function exists(string $alias): bool;

    /**
     * Removes an repository instance from the registry.
     *
     * @param string $alias The alias to remove.
     * @return void
     */
    function remove(string $alias): void;

    /**
     * Clears the registry of configuration and instances.
     *
     * @return void
     */
    function clear(): void;
}
