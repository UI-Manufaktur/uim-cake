module uim.cake.errors\Debug;

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
     * @return array<uim.cake.errors.debugs.INode>
     */
    auto getChildren(): array;

    /**
     * Get the contained value.
     *
     * @return mixed
     */
    auto getValue();
}
