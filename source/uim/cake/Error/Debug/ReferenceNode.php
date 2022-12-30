


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for class references.
 *
 * To prevent cyclic references from being output multiple times
 * a reference node can be used after an object has been seen the
 * first time.
 */
class ReferenceNode : NodeInterface
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
     * Constructor
     *
     * @param string $class The class name
     * @param int $id The id of the referenced class.
     */
    this(string $class, int $id) {
        this.class = $class;
        this.id = $id;
    }

    /**
     * Get the class name/value
     */
    string getValue(): string
    {
        return this.class;
    }

    /**
     * Get the reference id for this node.
     *
     * @return int
     */
    function getId(): int
    {
        return this.id;
    }


    function getChildren(): array
    {
        return [];
    }
}
