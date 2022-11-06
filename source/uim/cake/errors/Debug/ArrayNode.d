module uim.cakerors\Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : INode
{
    /**
     * @var array<\Cake\Error\Debug\ArrayItemNode>
     */
    private myItems;

    /**
     * Constructor
     *
     * @param array<\Cake\Error\Debug\ArrayItemNode> myItems The items for the array
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
     * @param \Cake\Error\Debug\ArrayItemNode myNode The item to add.
     * @return void
     */
    function add(ArrayItemNode myNode): void
    {
        this.items[] = myNode;
    }

    /**
     * Get the contained items
     *
     * @return array<\Cake\Error\Debug\ArrayItemNode>
     */
    auto getValue(): array
    {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<\Cake\Error\Debug\ArrayItemNode>
     */
    auto getChildren(): array
    {
        return this.items;
    }
}
