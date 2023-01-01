


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : INode
{
    /**
     * @var uim.cake.Error\debugs.INode
     */
    private $key;

    /**
     * @var uim.cake.Error\debugs.INode
     */
    private $value;

    /**
     * Constructor
     *
     * @param uim.cake.Error\debugs.INode $key The node for the item key
     * @param uim.cake.Error\debugs.INode $value The node for the array value
     */
    this(INode $key, INode $value) {
        this.key = $key;
        this.value = $value;
    }

    /**
     * Get the value
     *
     * @return uim.cake.Error\debugs.INode
     */
    function getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return uim.cake.Error\debugs.INode
     */
    function getKey() {
        return this.key;
    }


    function getChildren(): array
    {
        return [this.value];
    }
}
