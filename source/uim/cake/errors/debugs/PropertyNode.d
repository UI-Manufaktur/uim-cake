module uim.cake.errors.debugs.propertynode;

@safe:
import uim.cake;

// Dump node for object properties.
class PropertyNode : INode {
    private string myName;

    /**
     * @var string|null
     */
    private $visibility;

    /**
     * @var \Cake\Error\Debug\INode
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myName The property name
     * @param string|null $visibility The visibility of the property.
     * @param \Cake\Error\Debug\INode myValue The property value node.
     */
    this(string myName, Nullable!string $visibility, INode myValue) {
        this.name = myName;
        this.visibility = $visibility;
        this.value = myValue;
    }

    /**
     * Get the value
     *
     * @return \Cake\Error\Debug\INode
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
