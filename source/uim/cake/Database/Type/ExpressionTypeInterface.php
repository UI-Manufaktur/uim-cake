

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
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
     * @return \Cake\Database\IExpression
     */
    function toExpression($value): IExpression;
}
