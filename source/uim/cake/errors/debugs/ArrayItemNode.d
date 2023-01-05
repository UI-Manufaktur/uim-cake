module uim.cake.errors\Debug;

/**
 * Dump node for Array Items.
 */
class ArrayItemNode : INode
{
    /**
     * @var uim.cake.errors.debugs.INode
     */
    private myKey;

    /**
     * @var uim.cake.errors.debugs.INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param uim.cake.errors.debugs.INode myKey The node for the item key
     * @param uim.cake.errors.debugs.INode myValue The node for the array value
     */
    this(INode myKey, INode myValue) {
        this.key = myKey;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return uim.cake.errors.debugs.INode
     */
    auto getValue() {
        return this.value;
    }

    /**
     * Get the key
     *
     * @return uim.cake.errors.debugs.INode
     */
    auto getKey() {
        return this.key;
    }


    array getChildren()
    {
        return [this.value];
    }
}
