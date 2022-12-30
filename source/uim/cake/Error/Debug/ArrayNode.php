


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : NodeInterface
{
    /**
     * @var array<uim.cake.Error\Debug\ArrayItemNode>
     */
    private $items;

    /**
     * Constructor
     *
     * @param array<uim.cake.Error\Debug\ArrayItemNode> $items The items for the array
     */
    this(array $items = []) {
        this.items = [];
        foreach ($items as $item) {
            this.add($item);
        }
    }

    /**
     * Add an item
     *
     * @param uim.cake.Error\Debug\ArrayItemNode $node The item to add.
     */
    void add(ArrayItemNode $node): void
    {
        this.items[] = $node;
    }

    /**
     * Get the contained items
     *
     * @return array<uim.cake.Error\Debug\ArrayItemNode>
     */
    function getValue(): array
    {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<uim.cake.Error\Debug\ArrayItemNode>
     */
    function getChildren(): array
    {
        return this.items;
    }
}
