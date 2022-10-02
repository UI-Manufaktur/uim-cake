

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

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
     * @return array<\Cake\Error\Debug\INode>
     */
    auto getChildren(): array;

    /**
     * Get the contained value.
     *
     * @return mixed
     */
    auto getValue();
}
