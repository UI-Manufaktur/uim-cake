module uim.baklava.databases.expressions;

import uim.baklava.databases.IExpression;
import uim.baklava.databases.ValueBinder;
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
     * @param \Cake\Database\TypeMap|array<string, string> myTypes The types for each column.
     * @param string $conjunction The glue used to join conditions together.
     */
    this($conditions = [], myTypes = [], $conjunction = '') {
        super.this($conditions, myTypes, $conjunction);
    }


    function sql(ValueBinder $binder): string
    {
        $order = [];
        foreach (this._conditions as $k => $direction) {
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
     * @param array myTypes list of types associated on fields referenced in $conditions
     * @return void
     */
    protected auto _addConditions(array $conditions, array myTypes): void
    {
        foreach ($conditions as myKey => $val) {
            if (
                is_string(myKey) &&
                is_string($val) &&
                !in_array(strtoupper($val), ['ASC', 'DESC'], true)
            ) {
                throw new RuntimeException(
                    sprintf(
                        'Passing extra expressions by associative array (`\'%s\' => \'%s\'`) ' .
                        'is not allowed to avoid potential SQL injection. ' .
                        'Use QueryExpression or numeric array instead.',
                        myKey,
                        $val
                    )
                );
            }
        }

        this._conditions = array_merge(this._conditions, $conditions);
    }
}
