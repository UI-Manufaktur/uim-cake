module uim.cake.orm.Locator;

import uim.cake.datasources.Locator\ILocatoras BaseILocator;
import uim.cake.datasources.IRepository;
import uim.cake.orm.Table;

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
    array getConfig(?string $alias = null);

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
     * @return uim.cake.orm.Table
     */
    function get(string $alias, array $options = []): Table;

    /**
     * Set a table instance.
     *
     * @param string $alias The alias to set.
     * @param uim.cake.orm.Table $repository The table to set.
     * @return uim.cake.orm.Table
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function set(string $alias, IRepository $repository): Table;
}
