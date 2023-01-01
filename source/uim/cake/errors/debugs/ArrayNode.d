module uim.cake.errors\Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : INode
{
    /**
     * @var array<uim.cake.Error\debugs.ArrayItemNode>
     */
    private myItems;

    /**
     * Constructor
     *
     * @param array<uim.cake.Error\debugs.ArrayItemNode> myItems The items for the array
     */
    this(array myItems = []) {
        this.items = [];
        foreach (myItems as $item) {
            this.add($item);
        }
    }

    /**
     * Add an item
     *
     * @param uim.cake.Error\debugs.ArrayItemNode myNode The item to add.
     */
    void add(ArrayItemNode myNode): void
    {
        this.items[] = myNode;
    }

    /**
     * Get the contained items
     *
     * @return array<uim.cake.Error\debugs.ArrayItemNode>
     */
    auto getValue(): array
    {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<uim.cake.Error\debugs.ArrayItemNode>
     */
    auto getChildren(): array
    {
        return this.items;
    }
}
