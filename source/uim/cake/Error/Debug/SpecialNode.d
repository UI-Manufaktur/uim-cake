

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

/**
 * Debug node for special messages like errors or recursion warnings.
 */
class SpecialNode : INode
{
    /**
     * @var string
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myValue The message/value to include in dump results.
     */
    this(string myValue)
    {
        this.value = myValue;
    }

    /**
     * Get the message/value
     *
     * @return string
     */
    auto getValue(): string
    {
        return this.value;
    }


    auto getChildren(): array
    {
        return [];
    }
}
