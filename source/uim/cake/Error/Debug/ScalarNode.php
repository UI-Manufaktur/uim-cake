


 *


 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Dump node for scalar values.
 */
class ScalarNode : NodeInterface
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
    public this(string $type, $value) {
        this.type = $type;
        this.value = $value;
    }

    /**
     * Get the type of value
     *
     * @return string
     */
    function getType(): string
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
