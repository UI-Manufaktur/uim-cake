/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.Debug;

// Dump node for object properties.
class PropertyNode : INode {
    private string myName;

    /**
     * @var string|null
     */
    private $visibility;

    /**
     * @var uim.cake.errors.debugs.INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myName The property name
     * @param string|null $visibility The visibility of the property.
     * @param uim.cake.errors.debugs.INode myValue The property value node.
     */
    this(string myName, Nullable!string visibility, INode myValue) {
        this.name = myName;
        this.visibility = $visibility;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return uim.cake.errors.debugs.INode
     */
    INode getValue() {
      return this.value;
    }

    // Get the property visibility
    string getVisibility() {
      return this.visibility;
    }

    // Get the property name
    string getName() {
      return this.name;
    }

    array getChildren() {
      return [this.value];
    }
}
