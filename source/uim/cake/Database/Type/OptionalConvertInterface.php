


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

/**
 * An interface used by Type objects to signal whether the casting
 * is actually required.
 */
interface OptionalConvertInterface
{
    /**
     * Returns whether the cast to PHP is required to be invoked, since
     * it is not a identity function.
     *
     * @return bool
     */
    function requiresToPhpCast(): bool;
}
