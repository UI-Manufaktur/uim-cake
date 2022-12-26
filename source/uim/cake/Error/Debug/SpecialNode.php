


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Debug;

/**
 * Debug node for special messages like errors or recursion warnings.
 */
class SpecialNode : NodeInterface
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
    public this(string $value) {
        this.value = $value;
    }

    /**
     * Get the message/value
     *
     * @return string
     */
    function getValue(): string
    {
        return this.value;
    }

    /**
     * @inheritDoc
     */
    function getChildren(): array
    {
        return [];
    }
}
