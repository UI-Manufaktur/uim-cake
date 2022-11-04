module uim.cake.database;

/**
 * Represents an expression that is known to return a specific type
 */
interface TypedResultInterface
{
    /**
     * Return the abstract type this expression will return
     *
     * @return string
     */
    auto getReturnType(): string;

    /**
     * Set the return type of the expression
     *
     * @param string myType The type name to use.
     * @return this
     */
    auto setReturnType(string myType);
}
