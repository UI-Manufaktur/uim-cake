


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use RuntimeException;

/**
 * An expression object for ORDER BY clauses
 */
class OrderByExpression : QueryExpression
{
    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|array|string $conditions The sort columns
     * @param \Cake\Database\TypeMap|array<string, string> $types The types for each column.
     * @param string $conjunction The glue used to join conditions together.
     */
    public this($conditions = [], $types = [], $conjunction = '') {
        super(($conditions, $types, $conjunction);
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $order = [];
        foreach (_conditions as $k: $direction) {
            if ($direction instanceof IExpression) {
                $direction = $direction.sql($binder);
            }
            $order[] = is_numeric($k) ? $direction : sprintf('%s %s', $k, $direction);
        }

        return sprintf('ORDER BY %s', implode(', ', $order));
    }

    /**
     * Auxiliary function used for decomposing a nested array of conditions and
     * building a tree structure inside this object to represent the full SQL expression.
     *
     * New order by expressions are merged to existing ones
     *
     * @param array $conditions list of order by expressions
     * @param array $types list of types associated on fields referenced in $conditions
     * @return void
     */
    protected function _addConditions(array $conditions, array $types): void
    {
        foreach ($conditions as $key: $val) {
            if (
                is_string($key) &&
                is_string($val) &&
                !in_array(strtoupper($val), ['ASC', 'DESC'], true)
            ) {
                throw new RuntimeException(
                    sprintf(
                        'Passing extra expressions by associative array (`\'%s\': \'%s\'`) ' .
                        'is not allowed to avoid potential SQL injection. ' .
                        'Use QueryExpression or numeric array instead.',
                        $key,
                        $val
                    )
                );
            }
        }

        _conditions = array_merge(_conditions, $conditions);
    }
}
