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
 * $table = TableRegistry::getTableLocator().get("Users", aConfig);
 *
 * // Prior to 3.6.0
 * $table = TableRegistry::get("Users", aConfig);
 * ```
 */
class TableRegistry
{
    /**
     * Returns a singleton instance of ILocatorimplementation.
     *
     * @return uim.cake.orm.Locator\ILocator
     */
    static function getTableLocator(): ILocator
    {
        /** @var uim.cake.orm.Locator\ILocator*/
        return FactoryLocator::get("Table");
    }

    /**
     * Sets singleton instance of ILocatorimplementation.
     *
     * @param uim.cake.orm.Locator\ILocator $tableLocator Instance of a locator to use.
     */
    static void setTableLocator(ILocator $tableLocator) {
        FactoryLocator::add("Table", $tableLocator);
    }

    /**
     * Get a table instance from the registry.
     *
     * See options specification in {@link TableLocator::get()}.
     *
     * @param string $alias The alias name you want to get.
     * @param array<string, mixed> $options The options you want to build the table with.
     * @return uim.cake.orm.Table
     * @deprecated 3.6.0 Use {@link uim.cake.orm.Locator\LocatorAwareTrait::fetchTable()} instead. Will be removed in 5.0.
     */
    static function get(string $alias, array $options = []): Table
    {
        return static::getTableLocator().get($alias, $options);
    }

    /**
     * Check to see if an instance exists in the registry.
     *
     * @param string $alias The alias to check for.
     * @return bool
     * @deprecated 3.6.0 Use {@link uim.cake.orm.Locator\TableLocator::exists()} instead. Will be removed in 5.0
     */
    static bool exists(string $alias) {
        return static::getTableLocator().exists($alias);
    }

    /**
     * Set an instance.
     *
     * @param string $alias The alias to set.
     * @param uim.cake.orm.Table $object The table to set.
     * @return uim.cake.orm.Table
     * @deprecated 3.6.0 Use {@link uim.cake.orm.Locator\TableLocator::set()} instead. Will be removed in 5.0
     */
    static function set(string $alias, Table $object): Table
    {
        return static::getTableLocator().set($alias, $object);
    }

    /**
     * Removes an instance from the registry.
     *
     * @param string $alias The alias to remove.
     * @return void
     * @deprecated 3.6.0 Use {@link uim.cake.orm.Locator\TableLocator::remove()} instead. Will be removed in 5.0
     */
    static void remove(string $alias) {
        static::getTableLocator().remove($alias);
    }

    /**
     * Clears the registry of configuration and instances.
     *
     * @return void
     * @deprecated 3.6.0 Use {@link uim.cake.orm.Locator\TableLocator::clear()} instead. Will be removed in 5.0
     */
    static void clear() {
        static::getTableLocator().clear();
    }
}
