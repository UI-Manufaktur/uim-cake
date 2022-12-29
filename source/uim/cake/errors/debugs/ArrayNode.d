module uim.cake.errors\Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : INode
{
    /**
     * @var array<uim.cake.Error\Debug\ArrayItemNode>
     */
    private myItems;

    /**
     * Constructor
     *
     * @param array<uim.cake.Error\Debug\ArrayItemNode> myItems The items for the array
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
     * @param uim.cake.Error\Debug\ArrayItemNode myNode The item to add.
     * @return void
     */
    function add(ArrayItemNode myNode): void
    {
        this.items[] = myNode;
    }

    /**
     * Get the contained items
     *
     * @return array<uim.cake.Error\Debug\ArrayItemNode>
     */
    auto getValue(): array
    {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<uim.cake.Error\Debug\ArrayItemNode>
     */
    auto getChildren(): array
    {
        return this.items;
    }
}
