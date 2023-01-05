


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for object properties.
 */
class PropertyNode : INode
{
    /**
     * @var string
     */
    private $name;

    /**
     * @var string|null
     */
    private $visibility;

    /**
     * @var uim.cake.errors.debugs.INode
     */
    private $value;

    /**
     * Constructor
     *
     * @param string aName The property name
     * @param string|null $visibility The visibility of the property.
     * @param uim.cake.errors.debugs.INode $value The property value node.
     */
    this(string aName, ?string $visibility, INode $value) {
        this.name = $name;
        this.visibility = $visibility;
        this.value = $value;
    }

    /**
     * Get the value
     *
     * @return uim.cake.errors.debugs.INode
     */
    function getValue(): INode
    {
        return this.value;
    }

    /**
     * Get the property visibility
     */
    string getVisibility(): ?string
    {
        return this.visibility;
    }

    /**
     * Get the property name
     */
    string getName() {
        return this.name;
    }


    array getChildren() {
        return [this.value];
    }
}
