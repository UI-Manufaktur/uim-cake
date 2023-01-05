module uim.cake.errors\Debug;

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
     * @var array<uim.cake.errors.debugs.PropertyNode>
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
     * @param uim.cake.errors.debugs.PropertyNode myNode The property to add.
     */
    void addProperty(PropertyNode myNode) {
        this.properties[] = myNode;
    }

    /**
     * Get the class name
     */
    string getValue() {
        return this.class;
    }

    /**
     * Get the reference id
     */
    int getId() {
        return this.id;
    }

    /**
     * Get property nodes
     *
     * @return array<uim.cake.errors.debugs.PropertyNode>
     */
    array getChildren() {
        return this.properties;
    }
}
