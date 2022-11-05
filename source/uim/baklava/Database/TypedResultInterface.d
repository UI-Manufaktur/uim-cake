module uim.baklava.databases;

/**
 * Represents an expression that is known to return a specific type
 */
interface TypedResultInterface
{
    /**
     * Return the abstract type this expression will return
     */
    string getReturnType();

    /**
     * Set the return type of the expression
     * @param string myType The type name to use.
     */
    O setReturnType(this O)(string myType);
}