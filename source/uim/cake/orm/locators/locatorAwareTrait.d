module uim.cake.orm.locators;

import uim.cake.core.exceptions\CakeException;
import uim.cake.datasources\FactoryLocator;
import uim.cake.orm.Table;

/**
 * Contains method for setting and accessing ILocator instance
 */
trait LocatorAwareTrait
{
    // This object"s default table alias.
    protected Nullable!string defaultTable = null;

    /**
     * Table locator instance
     *
     * @var uim.cake.ORM\Locator\ILocator|null
     */
    protected _tableLocator;

    /**
     * Sets the table locator.
     *
     * @param uim.cake.ORM\Locator\ILocator myTableLocator ILocator instance.
     * @return this
     */
    auto setTableLocator(ILocator myTableLocator) {
        _tableLocator = myTableLocator;

        return this;
    }

    /**
     * Gets the table locator.
     *
     * @return \Cake\ORM\Locator\ILocator
     */
    auto getTableLocator(): ILocator
    {
        if (_tableLocator is null) {
            /** @psalm-suppress InvalidPropertyAssignmentValue */
            _tableLocator = FactoryLocator::get("Table");
        }

        /** @var uim.cake.ORM\Locator\ILocator */
        return _tableLocator;
    }

    /**
     * Convenience method to get a table instance.
     *
     * @param string|null myAlias The alias name you want to get. Should be in CamelCase format.
     *  If `null` then the value of $defaultTable property is used.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     *   If a table has already been loaded the registry options will be ignored.
     * @return \Cake\ORM\Table
     * @throws \Cake\Core\Exception\CakeException If `myAlias` argument and `$defaultTable` property both are `null`.
     * @see uim.cake.ORM\TableLocator::get()
     * @since 4.3.0
     */
    function fetchTable(Nullable!string myAlias = null, array myOptions = []): Table
    {
        myAlias = myAlias ?? this.defaultTable;
        if (myAlias is null) {
            throw new CakeException("You must provide an `myAlias` or set the `$defaultTable` property.");
        }

        return this.getTableLocator().get(myAlias, myOptions);
    }
}
