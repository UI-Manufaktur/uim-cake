module uim.cake.orm;

@safe:
import uim.cake;

/**
 * Provides a registry/factory for Table objects.
 *
 * This registry allows you to centralize the configuration for tables
 * their connections and other meta-data.
 *
 * ### Configuring instances
 *
 * You may need to configure your table objects. Using the `TableLocator` you can
 * centralize configuration. Any configuration set before instances are created
 * will be used when creating instances. If you modify configuration after
 * an instance is made, the instances *will not* be updated.
 *
 * ```
 * TableRegistry::getTableLocator().setConfig("Users", ["table": "my_users"]);
 *
 * // Prior to 3.6.0
 * TableRegistry::config("Users", ["table": "my_users"]);
 * ```
 *
 * Configuration data is stored *per alias* if you use the same table with
 * multiple aliases you will need to set configuration multiple times.
 *
 * ### Getting instances
 *
 * You can fetch instances out of the registry through `TableLocator::get()`.
 * One instance is stored per alias. Once an alias is populated the same
 * instance will always be returned. This reduces the ORM memory cost and
 * helps make cyclic references easier to solve.
 *
 * ```
 * myTable = TableRegistry::getTableLocator().get("Users", myConfig);
 *
 * // Prior to 3.6.0
 * myTable = TableRegistry::get("Users", myConfig);
 * ```
 */
class TableRegistry
{
    /**
     * Returns a singleton instance of ILocator implementation.
     *
     * @return uim.cake.ORM\Locator\ILocator
     */
    static auto getTableLocator(): ILocator
    {
        /** @var uim.cake.ORM\Locator\ILocator */
        return FactoryLocator::get("Table");
    }

    /**
     * Sets singleton instance of ILocator implementation.
     *
     * @param uim.cake.ORM\Locator\ILocator myTableLocator Instance of a locator to use.
     * @return void
     */
    static void setTableLocator(ILocator myTableLocator) {
        FactoryLocator::add("Table", myTableLocator);
    }

    /**
     * Get a table instance from the registry.
     *
     * See options specification in {@link TableLocator::get()}.
     *
     * @param string myAlias The alias name you want to get.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     * @return uim.cake.ORM\Table
     * @deprecated 3.6.0 Use {@link uim.cake.ORM\Locator\TableLocator::get()} instead. Will be removed in 5.0.
     */
    static auto get(string myAlias, array myOptions = []): Table
    {
        return static::getTableLocator().get(myAlias, myOptions);
    }

    /**
     * Check to see if an instance exists in the registry.
     *
     * @param string myAlias The alias to check for.
     * @return bool
     * @deprecated 3.6.0 Use {@link uim.cake.ORM\Locator\TableLocator::exists()} instead. Will be removed in 5.0
     */
    static bool exists(string myAlias) {
        return static::getTableLocator().exists(myAlias);
    }

    /**
     * Set an instance.
     *
     * @param string myAlias The alias to set.
     * @param uim.cake.ORM\Table $object The table to set.
     * @return uim.cake.ORM\Table
     * @deprecated 3.6.0 Use {@link uim.cake.ORM\Locator\TableLocator::set()} instead. Will be removed in 5.0
     */
    static Table set(string myAlias, Table tableObject) {
        return static::getTableLocator().set(myAlias, tableObject);
    }

    /**
     * Removes an instance from the registry.
     *
     * @param string myAlias The alias to remove.
     * @deprecated 3.6.0 Use {@link uim.cake.ORM\Locator\TableLocator::remove()} instead. Will be removed in 5.0
     */
    static void remove(string myAlias) {
        static::getTableLocator().remove(myAlias);
    }

    /**
     * Clears the registry of configuration and instances.
     * @deprecated 3.6.0 Use {@link uim.cake.ORM\Locator\TableLocator::clear()} instead. Will be removed in 5.0
     */
    static void clear() {
        static::getTableLocator().clear();
    }
}
