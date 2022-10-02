

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.database.Type;

import uim.cake.database.IExpression;

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
     * @param mixed myValue The value to be converted to an expression
     * @return \Cake\Database\IExpression
     */
    function toExpression(myValue): IExpression;
}
