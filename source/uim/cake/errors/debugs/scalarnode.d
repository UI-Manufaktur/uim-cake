


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Dump node for scalar values.
 */
class ScalarNode : INode
{
    /**
     * @var string
     */
    private $type;

    /**
     * @var string|float|int|bool|null
     */
    private $value;

    /**
     * Constructor
     *
     * @param string $type The type of scalar value.
     * @param string|float|int|bool|null $value The wrapped value.
     */
    this(string $type, $value) {
        this.type = $type;
        this.value = $value;
    }

    /**
     * Get the type of value
     */
    string getType()
    {
        return this.type;
    }

    /**
     * Get the value
     *
     * @return string|float|int|bool|null
     */
    function getValue() {
        return this.value;
    }


    function getChildren(): array
    {
        return [];
    }
}
