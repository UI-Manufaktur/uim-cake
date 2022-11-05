module uim.baklava.errors\Debug;

/**
 * Dump node for objects/class instances.
 */
class ClassNode : INode
{
    /**
     * @var string
     */
    private myClass;

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
     * @param string myClass The class name
     * @param int $id The reference id of this object in the DumpContext
     */
    this(string myClass, int $id) {
        this.class = myClass;
        this.id = $id;
    }

    /**
     * Add a property
     *
     * @param \Cake\Error\Debug\PropertyNode myNode The property to add.
     * @return void
     */
    function addProperty(PropertyNode myNode): void
    {
        this.properties[] = myNode;
    }

    /**
     * Get the class name
     *
     * @return string
     */
    string getValue() {
        return this.class;
    }

    /**
     * Get the reference id
     *
     * @return int
     */
    auto getId(): int
    {
        return this.id;
    }

    /**
     * Get property nodes
     *
     * @return array<\Cake\Error\Debug\PropertyNode>
     */
    auto getChildren(): array
    {
        return this.properties;
    }
}
