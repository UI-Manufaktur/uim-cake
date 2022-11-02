module uim.cake.errors\Debug;

/**
 * Dump node for scalar values.
 */
class ScalarNode : INode
{
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
     *
     * @return string
     */
    auto getType(): string
    {
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


    auto getChildren(): array
    {
        return [];
    }
}
