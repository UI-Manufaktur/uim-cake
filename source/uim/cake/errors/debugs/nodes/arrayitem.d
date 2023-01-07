/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.debugs.nodes;

// Dump node for Array Items.
class ArrayItemNode : INode {
  private INode _key;

  private INode _value;

  /**
    * Constructor
    *
    * aKey - The node for the item key
    * aValue - The node for the array value
    */
  this(INode aKey, INode aValue) {
      _key = aKey;
      _value = myValue;
  }

  // Get value
  @property INode value() {
    return _value;
  }

  // Get the key
  @property INode key() {
    return _key;
  }

  array getChildren() {
    return [this.value];
  }
}
