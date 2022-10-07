

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

/**
 * Dump node for class references.
 *
 * To prevent cyclic references from being output multiple times
 * a reference node can be used after an object has been seen the
 * first time.
 */
class ReferenceNode : INode {
    private string myClass;

    /**
     * @var int
     */
    private $id;

    /**
     * Constructor
     *
     * @param string myClass The class name
     * @param int $id The id of the referenced class.
     */
    this(string myClass, int $id)
    {
        this.class = myClass;
        this.id = $id;
    }

    /**
     * Get the class name/value
     *
     * @return string
     */
    auto getValue(): string
    {
        return this.class;
    }

    /**
     * Get the reference id for this node.
     *
     * @return int
     */
    auto getId(): int
    {
        return this.id;
    }


    auto getChildren(): array
    {
        return [];
    }
}
