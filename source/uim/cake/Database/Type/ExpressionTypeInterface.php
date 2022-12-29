


 *


 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.databases.IExpression;

/**
 * An interface used by Type objects to signal whether the value should
 * be converted to an IExpression instead of a string when sent
 * to the database.
 */
interface ExpressionTypeInterface
{
    /**
     * Returns an IExpression object for the given value that can
     * be used in queries.
     *
     * @param mixed $value The value to be converted to an expression
     * @return uim.cake.Database\IExpression
     */
    function toExpression($value): IExpression;
}
