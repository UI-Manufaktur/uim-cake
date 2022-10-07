

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

/**
 * Dump node for object properties.
 */
class PropertyNode : INode
{
    /**
     * @var string
     */
    private myName;

    /**
     * @var string|null
     */
    private $visibility;

    /**
     * @var \Cake\Error\Debug\INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myName The property name
     * @param string|null $visibility The visibility of the property.
     * @param \Cake\Error\Debug\INode myValue The property value node.
     */
    this(string myName, ?string $visibility, INode myValue)
    {
        this.name = myName;
        this.visibility = $visibility;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return \Cake\Error\Debug\INode
     */
    auto getValue(): INode
    {
        return this.value;
    }

    /**
     * Get the property visibility
     *
     * @return string
     */
    string getVisibility()
    {
        return this.visibility;
    }

    /**
     * Get the property name
     *
     * @return string
     */
    auto getName(): string
    {
        return this.name;
    }


    auto getChildren(): array
    {
        return [this.value];
    }
}
