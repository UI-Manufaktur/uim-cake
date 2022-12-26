


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

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
    public this(string $class, int $id) {
        this.class = $class;
        this.id = $id;
    }

    /**
     * Get the class name/value
     *
     * @return string
     */
    function getValue(): string
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

    /**
     * @inheritDoc
     */
    function getChildren(): array
    {
        return [];
    }
}
