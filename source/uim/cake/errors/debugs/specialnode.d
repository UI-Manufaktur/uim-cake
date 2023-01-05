


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Debug node for special messages like errors or recursion warnings.
 */
class SpecialNode : INode
{
    /**
     * @var string
     */
    private $value;

    /**
     * Constructor
     *
     * @param string $value The message/value to include in dump results.
     */
    this(string $value) {
        this.value = $value;
    }

    /**
     * Get the message/value
     */
    string getValue() {
        return this.value;
    }


    array getChildren() {
        return [];
    }
}
