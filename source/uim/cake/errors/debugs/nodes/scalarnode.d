/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.debugs.nodes;

/**
 * Dump node for scalar values.
 */
class ScalarNode : INode {
    /**
     * @var string
     */
    private myType;

    /**
     * @var string|float|int|bool|null
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myType The type of scalar value.
     * @param string|float|int|bool|null myValue The wrapped value.
     */
    this(string myType, myValue) {
        this.type = myType;
        this.value = myValue;
    }

    /**
     * Get the type of value
     */
    string getType() {
        return this.type;
    }

    /**
     * Get the value
     *
     * @return string|float|int|bool|null
     */
    auto getValue() {
        return this.value;
    }


    array getChildren() {
        return [];
    }
}
