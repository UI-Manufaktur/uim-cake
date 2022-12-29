


 *


 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Dump node for objects/class instances.
 */
class ClassNode : NodeInterface
{
    /**
     * @var string
     */
    private $class;

    /**
     * @var int
     */
    private $id;

    /**
     * @var array<\Cake\Error\Debug\PropertyNode>
     */
    private $properties = [];

    /**
     * Constructor
     *
     * @param string $class The class name
     * @param int $id The reference id of this object in the DumpContext
     */
    public this(string $class, int $id) {
        this.class = $class;
        this.id = $id;
    }

    /**
     * Add a property
     *
     * @param \Cake\Error\Debug\PropertyNode $node The property to add.
     * @return void
     */
    function addProperty(PropertyNode $node): void
    {
        this.properties[] = $node;
    }

    /**
     * Get the class name
     *
     * @return string
     */
    function getValue(): string
    {
        return this.class;
    }

    /**
     * Get the reference id
     *
     * @return int
     */
    function getId(): int
    {
        return this.id;
    }

    /**
     * Get property nodes
     *
     * @return array<\Cake\Error\Debug\PropertyNode>
     */
    function getChildren(): array
    {
        return this.properties;
    }
}
