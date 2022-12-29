


 *


 * @since         3.3.0
  */
module uim.cake.Datasource;

import uim.cake.datasources.Locator\ILocator;
import uim.cake.orm.locators.TableLocator;
use InvalidArgumentException;

/**
 * Class FactoryLocator
 */
class FactoryLocator
{
    /**
     * A list of model factory functions.
     *
     * @var array<callable|uim.cake.Datasource\Locator\ILocator>
     */
    protected static $_modelFactories = [];

    /**
     * Register a callable to generate repositories of a given type.
     *
     * @param string $type The name of the repository type the factory function is for.
     * @param uim.cake.Datasource\Locator\ILocator|callable $factory The factory function used to create instances.
     * @return void
     */
    static void add(string $type, $factory): void
    {
        if ($factory instanceof ILocator) {
            static::$_modelFactories[$type] = $factory;

            return;
        }

        if (is_callable($factory)) {
            deprecationWarning(
                "Using a callable as a locator has been deprecated."
                . " Use an instance of Cake\Datasource\Locator\ILocatorinstead."
            );

            static::$_modelFactories[$type] = $factory;

            return;
        }

        throw new InvalidArgumentException(sprintf(
            "`$factory` must be an instance of Cake\Datasource\Locator\ILocatoror a callable."
            . " Got type `%s` instead.",
            getTypeName($factory)
        ));
    }

    /**
     * Drop a model factory.
     *
     * @param string $type The name of the repository type to drop the factory for.
     * @return void
     */
    static void drop(string $type): void
    {
        unset(static::$_modelFactories[$type]);
    }

    /**
     * Get the factory for the specified repository type.
     *
     * @param string $type The repository type to get the factory for.
     * @throws \InvalidArgumentException If the specified repository type has no factory.
     * @return uim.cake.Datasource\Locator\ILocator|callable The factory for the repository type.
     */
    static function get(string $type) {
        if (!isset(static::$_modelFactories["Table"])) {
            static::$_modelFactories["Table"] = new TableLocator();
        }

        if (!isset(static::$_modelFactories[$type])) {
            throw new InvalidArgumentException(sprintf(
                "Unknown repository type "%s". Make sure you register a type before trying to use it.",
                $type
            ));
        }

        return static::$_modelFactories[$type];
    }
}
