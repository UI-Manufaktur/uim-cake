


 *


 * @since         3.1.0
  */
module uim.cake.orm.Locator;

import uim.cake.datasources.FactoryLocator;
import uim.cake.orm.Table;
use UnexpectedValueException;

/**
 * Contains method for setting and accessing ILocatorinstance
 */
trait LocatorAwareTrait
{
    /**
     * This object"s default table alias.
     *
     * @var string|null
     */
    protected $defaultTable = null;

    /**
     * Table locator instance
     *
     * @var uim.cake.ORM\Locator\ILocator|null
     */
    protected $_tableLocator;

    /**
     * Sets the table locator.
     *
     * @param uim.cake.ORM\Locator\ILocator $tableLocator ILocatorinstance.
     * @return this
     */
    function setTableLocator(ILocator $tableLocator) {
        _tableLocator = $tableLocator;

        return this;
    }

    /**
     * Gets the table locator.
     *
     * @return uim.cake.ORM\Locator\ILocator
     */
    function getTableLocator(): ILocator
    {
        if (_tableLocator == null) {
            /** @psalm-suppress InvalidPropertyAssignmentValue */
            _tableLocator = FactoryLocator::get("Table");
        }

        /** @var uim.cake.ORM\Locator\ILocator*/
        return _tableLocator;
    }

    /**
     * Convenience method to get a table instance.
     *
     * @param string|null $alias The alias name you want to get. Should be in CamelCase format.
     *  If `null` then the value of $defaultTable property is used.
     * @param array<string, mixed> $options The options you want to build the table with.
     *   If a table has already been loaded the registry options will be ignored.
     * @return uim.cake.ORM\Table
     * @throws uim.cake.Core\Exception\CakeException If `$alias` argument and `$defaultTable` property both are `null`.
     * @see uim.cake.ORM\TableLocator::get()
     * @since 4.3.0
     */
    function fetchTable(?string $alias = null, array $options = []): Table
    {
        $alias = $alias ?? this.defaultTable;
        if (empty($alias)) {
            throw new UnexpectedValueException(
                "You must provide an `$alias` or set the `$defaultTable` property to a non empty string."
            );
        }

        return this.getTableLocator().get($alias, $options);
    }
}
