module uim.cake.errors\Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : INode
{
    /**
     * @var array<uim.cake.errors.debugs.ArrayItemNode>
     */
    private myItems;

    /**
     * Constructor
     *
     * @param array<uim.cake.errors.debugs.ArrayItemNode> myItems The items for the array
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
     * @param uim.cake.errors.debugs.ArrayItemNode myNode The item to add.
     */
    void add(ArrayItemNode myNode) {
        this.items[] = myNode;
    }

    /**
     * Get the contained items
     *
     * @return array<uim.cake.errors.debugs.ArrayItemNode>
     */
    array getValue() {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<uim.cake.errors.debugs.ArrayItemNode>
     */
    array getChildren() {
        return this.items;
    }
}
