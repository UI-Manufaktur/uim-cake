


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Interface for Debugs
 *
 * Provides methods to look at contained value and iterate child nodes in the tree.
 */
interface INode
{
    /**
     * Get the child nodes of this node.
     *
     * @return array<uim.cake.Error\debugs.INode>
     */
    function getChildren(): array;

    /**
     * Get the contained value.
     *
     * @return mixed
     */
    function getValue();
}
