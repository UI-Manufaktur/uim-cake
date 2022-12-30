


 *


 * @since         3.2.0
  */module uim.cake.Database;

/**
 * Represents an expression that is known to return a specific type
 */
interface TypedResultInterface
{
    /**
     * Return the abstract type this expression will return
     */
    string getReturnType(): string;

    /**
     * Set the return type of the expression
     *
     * @param string $type The type name to use.
     * @return this
     */
    function setReturnType(string $type);
}
