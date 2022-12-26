


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : NodeInterface
{
    /**
     * @var \Cake\Error\Debug\NodeInterface
     */
    private $key;

    /**
     * @var \Cake\Error\Debug\NodeInterface
     */
    private $value;

    /**
     * Constructor
     *
     * @param \Cake\Error\Debug\NodeInterface $key The node for the item key
     * @param \Cake\Error\Debug\NodeInterface $value The node for the array value
     */
    public this(NodeInterface $key, NodeInterface $value) {
        this.key = $key;
        this.value = $value;
    }

    /**
     * Get the value
     *
     * @return \Cake\Error\Debug\NodeInterface
     */
    function getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return \Cake\Error\Debug\NodeInterface
     */
    function getKey() {
        return this.key;
    }

    /**
     * @inheritDoc
     */
    function getChildren(): array
    {
        return [this.value];
    }
}
