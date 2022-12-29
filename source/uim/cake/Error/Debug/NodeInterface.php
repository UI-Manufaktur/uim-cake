


 *


 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Interface for Debugs
 *
 * Provides methods to look at contained value and iterate child nodes in the tree.
 */
interface NodeInterface
{
    /**
     * Get the child nodes of this node.
     *
     * @return array<\Cake\Error\Debug\NodeInterface>
     */
    function getChildren(): array;

    /**
     * Get the contained value.
     *
     * @return mixed
     */
    function getValue();
}
