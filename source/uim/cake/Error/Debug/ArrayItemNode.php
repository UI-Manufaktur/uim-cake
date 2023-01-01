


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : NodeInterface
{
    /**
     * @var uim.cake.Error\debugs.NodeInterface
     */
    private $key;

    /**
     * @var uim.cake.Error\debugs.NodeInterface
     */
    private $value;

    /**
     * Constructor
     *
     * @param uim.cake.Error\debugs.NodeInterface $key The node for the item key
     * @param uim.cake.Error\debugs.NodeInterface $value The node for the array value
     */
    this(NodeInterface $key, NodeInterface $value) {
        this.key = $key;
        this.value = $value;
    }

    /**
     * Get the value
     *
     * @return uim.cake.Error\debugs.NodeInterface
     */
    function getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return uim.cake.Error\debugs.NodeInterface
     */
    function getKey() {
        return this.key;
    }


    function getChildren(): array
    {
        return [this.value];
    }
}
