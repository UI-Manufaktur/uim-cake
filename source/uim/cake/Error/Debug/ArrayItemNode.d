module uim.cake.errorss\Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : INode
{
    /**
     * @var \Cake\Error\Debug\INode
     */
    private myKey;

    /**
     * @var \Cake\Error\Debug\INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param \Cake\Error\Debug\INode myKey The node for the item key
     * @param \Cake\Error\Debug\INode myValue The node for the array value
     */
    this(INode myKey, INode myValue) {
        this.key = myKey;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return \Cake\Error\Debug\INode
     */
    auto getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return \Cake\Error\Debug\INode
     */
    auto getKey() {
        return this.key;
    }


    auto getChildren(): array
    {
        return [this.value];
    }
}
