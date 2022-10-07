

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

/**
 * Dump node for scalar values.
 */
class ScalarNode : INode
{
    /**
     * @var string
     */
    private myType;

    /**
     * @var string|float|int|bool|null
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myType The type of scalar value.
     * @param string|float|int|bool|null myValue The wrapped value.
     */
    this(string myType, myValue)
    {
        this.type = myType;
        this.value = myValue;
    }

    /**
     * Get the type of value
     *
     * @return string
     */
    auto getType(): string
    {
        return this.type;
    }

    /**
     * Get the value
     *
     * @return string|float|int|bool|null
     */
    auto getValue() {
        return this.value;
    }


    auto getChildren(): array
    {
        return [];
    }
}
