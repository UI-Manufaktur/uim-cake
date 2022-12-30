


 *


 * @since         4.1.0
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
     * @var array<uim.cake.Error\Debug\PropertyNode>
     */
    private $properties = [];

    /**
     * Constructor
     *
     * @param string $class The class name
     * @param int $id The reference id of this object in the DumpContext
     */
    this(string $class, int $id) {
        this.class = $class;
        this.id = $id;
    }

    /**
     * Add a property
     *
     * @param uim.cake.Error\Debug\PropertyNode $node The property to add.
     * @return void
     */
    void addProperty(PropertyNode $node): void
    {
        this.properties[] = $node;
    }

    /**
     * Get the class name
     */
    string getValue(): string
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
     * @return array<uim.cake.Error\Debug\PropertyNode>
     */
    function getChildren(): array
    {
        return this.properties;
    }
}
