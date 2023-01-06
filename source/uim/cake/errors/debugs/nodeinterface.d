/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.Debug;

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
    array getChildren();

    /**
     * Get the contained value.
     *
     * @return mixed
     */
    auto getValue();
}
