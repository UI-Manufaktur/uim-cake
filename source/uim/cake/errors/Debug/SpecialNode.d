module uim.cakerors\Debug;

/**
 * Debug node for special messages like errors or recursion warnings.
 */
class SpecialNode : INode
{
    /**
     * @var string
     */
    private myValue;

    /**
     * Constructor
     *
     * @param string myValue The message/value to include in dump results.
     */
    this(string myValue) {
        this.value = myValue;
    }

    /**
     * Get the message/value
     *
     * @return string
     */
    auto getValue(): string
    {
        return this.value;
    }


    auto getChildren(): array
    {
        return [];
    }
}
