module uim.cake.orm.locators;

import uim.cake.datasources\Locator\ILocator as BaseILocator;
import uim.cake.datasources\IRepository;
import uim.cake.orm.Table;

/**
 * Registries for Table objects should implement this interface.
 */
interface ILocator : BaseILocator
{
    /**
     * Returns configuration for an alias or the full configuration array for
     * all aliases.
     *
     * @param string|null myAlias Alias to get config for, null for complete config.
     * @return array The config data.
     */
    array getConfig(Nullable!string myAlias = null);

    /**
     * Stores a list of options to be used when instantiating an object
     * with a matching alias.
     *
     * @param array<string, mixed>|string myAlias Name of the alias or array to completely
     *   overwrite current config.
     * @param array<string, mixed>|null myOptions list of options for the alias
     * @return this
     * @throws \RuntimeException When you attempt to configure an existing
     *   table instance.
     */
    auto setConfig(myAlias, myOptions = null);

    /**
     * Get a table instance from the registry.
     *
     * @param string myAlias The alias name you want to get.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     * @return uim.cake.orm.Table
     */
    auto get(string myAlias, array myOptions = []): Table;

    /**
     * Set a table instance.
     *
     * @param string myAlias The alias to set.
     * @param uim.cake.orm.Table myRepository The table to set.
     * @return uim.cake.orm.Table
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    auto set(string myAlias, IRepository myRepository): Table;
}
