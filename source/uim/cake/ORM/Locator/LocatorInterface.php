


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Locator;

import uim.cake.Datasource\Locator\ILocatoras BaseILocator;
import uim.cake.Datasource\RepositoryInterface;
import uim.cake.ORM\Table;

/**
 * Registries for Table objects should implement this interface.
 */
interface ILocator: BaseILocator
{
    /**
     * Returns configuration for an alias or the full configuration array for
     * all aliases.
     *
     * @param string|null $alias Alias to get config for, null for complete config.
     * @return array The config data.
     */
    function getConfig(?string $alias = null): array;

    /**
     * Stores a list of options to be used when instantiating an object
     * with a matching alias.
     *
     * @param array<string, mixed>|string $alias Name of the alias or array to completely
     *   overwrite current config.
     * @param array<string, mixed>|null $options list of options for the alias
     * @return this
     * @throws \RuntimeException When you attempt to configure an existing
     *   table instance.
     */
    function setConfig($alias, $options = null);

    /**
     * Get a table instance from the registry.
     *
     * @param string $alias The alias name you want to get.
     * @param array<string, mixed> $options The options you want to build the table with.
     * @return \Cake\ORM\Table
     */
    function get(string $alias, array $options = []): Table;

    /**
     * Set a table instance.
     *
     * @param string $alias The alias to set.
     * @param \Cake\ORM\Table $repository The table to set.
     * @return \Cake\ORM\Table
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function set(string $alias, RepositoryInterface $repository): Table;
}
