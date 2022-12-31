


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for object properties.
 */
class PropertyNode : NodeInterface
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
     * @var uim.cake.Error\Debug\NodeInterface
     */
    private $value;

    /**
     * Constructor
     *
     * @param string aName The property name
     * @param string|null $visibility The visibility of the property.
     * @param uim.cake.Error\Debug\NodeInterface $value The property value node.
     */
    this(string aName, ?string $visibility, NodeInterface $value) {
        this.name = $name;
        this.visibility = $visibility;
        this.value = $value;
    }

    /**
     * Get the value
     *
     * @return uim.cake.Error\Debug\NodeInterface
     */
    function getValue(): NodeInterface
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
    string getName(): string
    {
        return this.name;
    }


    function getChildren(): array
    {
        return [this.value];
    }
}
