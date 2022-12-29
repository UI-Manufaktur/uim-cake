


 *


 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

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
    function getReturnType(): string;

    /**
     * Set the return type of the expression
     *
     * @param string $type The type name to use.
     * @return this
     */
    function setReturnType(string $type);
}
