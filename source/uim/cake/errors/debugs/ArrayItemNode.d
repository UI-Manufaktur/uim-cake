module uim.cake.errors\Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : INode
{
    /**
     * @var uim.cake.Error\Debug\INode
     */
    private myKey;

    /**
     * @var uim.cake.Error\Debug\INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param uim.cake.Error\Debug\INode myKey The node for the item key
     * @param uim.cake.Error\Debug\INode myValue The node for the array value
     */
    this(INode myKey, INode myValue) {
        this.key = myKey;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return uim.cake.Error\Debug\INode
     */
    auto getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return uim.cake.Error\Debug\INode
     */
    auto getKey() {
        return this.key;
    }


    auto getChildren(): array
    {
        return [this.value];
    }
}
