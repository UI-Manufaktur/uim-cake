

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Datasource;

import uim.cake.Datasource\Locator\ILocator;
import uim.cake.ORM\Locator\TableLocator;
use InvalidArgumentException;

/**
 * Class FactoryLocator
 */
class FactoryLocator
{
    /**
     * A list of model factory functions.
     *
     * @var array<callable|\Cake\Datasource\Locator\ILocator>
     */
    protected static $_modelFactories = [];

    /**
     * Register a callable to generate repositories of a given type.
     *
     * @param string myType The name of the repository type the factory function is for.
     * @param \Cake\Datasource\Locator\ILocator|callable $factory The factory function used to create instances.
     * @return void
     */
    static function add(string myType, $factory): void
    {
        if (!$factory instanceof ILocator && !is_callable($factory)) {
            throw new InvalidArgumentException(sprintf(
                '`$factory` must be an instance of Cake\Datasource\Locator\ILocator or a callable.'
                . ' Got type `%s` instead.',
                getTypeName($factory)
            ));
        }

        static::$_modelFactories[myType] = $factory;
    }

    /**
     * Drop a model factory.
     *
     * @param string myType The name of the repository type to drop the factory for.
     * @return void
     */
    static function drop(string myType): void
    {
        unset(static::$_modelFactories[myType]);
    }

    /**
     * Get the factory for the specified repository type.
     *
     * @param string myType The repository type to get the factory for.
     * @throws \InvalidArgumentException If the specified repository type has no factory.
     * @return \Cake\Datasource\Locator\ILocator|callable The factory for the repository type.
     */
    static auto get(string myType) {
        if (!isset(static::$_modelFactories['Table'])) {
            static::$_modelFactories['Table'] = new TableLocator();
        }

        if (!isset(static::$_modelFactories[myType])) {
            throw new InvalidArgumentException(sprintf(
                'Unknown repository type "%s". Make sure you register a type before trying to use it.',
                myType
            ));
        }

        return static::$_modelFactories[myType];
    }
}
