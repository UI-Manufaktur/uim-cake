


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Dump node for Array values.
 */
class ArrayNode : NodeInterface
{
    /**
     * @var array<\Cake\Error\Debug\ArrayItemNode>
     */
    private $items;

    /**
     * Constructor
     *
     * @param array<\Cake\Error\Debug\ArrayItemNode> $items The items for the array
     */
    public this(array $items = []) {
        this.items = [];
        foreach ($items as $item) {
            this.add($item);
        }
    }

    /**
     * Add an item
     *
     * @param \Cake\Error\Debug\ArrayItemNode $node The item to add.
     * @return void
     */
    function add(ArrayItemNode $node): void
    {
        this.items[] = $node;
    }

    /**
     * Get the contained items
     *
     * @return array<\Cake\Error\Debug\ArrayItemNode>
     */
    function getValue(): array
    {
        return this.items;
    }

    /**
     * Get Item nodes
     *
     * @return array<\Cake\Error\Debug\ArrayItemNode>
     */
    function getChildren(): array
    {
        return this.items;
    }
}
