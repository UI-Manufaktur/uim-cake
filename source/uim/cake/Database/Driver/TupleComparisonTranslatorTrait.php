module uim.cake.database.Driver;

import uim.cake.database.Expression\IdentifierExpression;
import uim.cake.database.Expression\QueryExpression;
import uim.cake.database.Expression\TupleComparison;
import uim.cake.database.Query;
use RuntimeException;

/**
 * Provides a translator method for tuple comparisons
 *
 * @internal
 */
trait TupleComparisonTranslatorTrait
{
    /**
     * Receives a TupleExpression and changes it so that it conforms to this
     * SQL dialect.
     *
     * It transforms expressions looking like '(a, b) IN ((c, d), (e, f))' into an
     * equivalent expression of the form '((a = c) AND (b = d)) OR ((a = e) AND (b = f))'.
     *
     * It can also transform transform expressions where the right hand side is a query
     * selecting the same amount of columns as the elements in the left hand side of
     * the expression:
     *
     * (a, b) IN (SELECT c, d FROM a_table) is transformed into
     *
     * 1 = (SELECT 1 FROM a_table WHERE (a = c) AND (b = d))
     *
     * @param \Cake\Database\Expression\TupleComparison $expression The expression to transform
     * @param \Cake\Database\Query myQuery The query to update.
     * @return void
     */
    protected auto _transformTupleComparison(TupleComparison $expression, Query myQuery): void
    {
        myFields = $expression.getField();

        if (!is_array(myFields)) {
            return;
        }

        $operator = strtoupper($expression.getOperator());
        if (!in_array($operator, ['IN', '='])) {
            throw new RuntimeException(
                sprintf(
                    'Tuple comparison transform only supports the `IN` and `=` operators, `%s` given.',
                    $operator
                )
            );
        }

        myValue = $expression.getValue();
        $true = new QueryExpression('1');

        if (myValue instanceof Query) {
            $selected = array_values(myValue.clause('select'));
            foreach (myFields as $i => myField) {
                myValue.andWhere([myField => new IdentifierExpression($selected[$i])]);
            }
            myValue.select($true, true);
            $expression.setField($true);
            $expression.setOperator('=');

            return;
        }

        myType = $expression.getType();
        if (myType) {
            /** @var array<string, string> myTypeMap */
            myTypeMap = array_combine(myFields, myType) ?: [];
        } else {
            myTypeMap = [];
        }

        $surrogate = myQuery.getConnection()
            .newQuery()
            .select($true);

        if (!is_array(current(myValue))) {
            myValue = [myValue];
        }

        $conditions = ['OR' => []];
        foreach (myValue as $tuple) {
            $item = [];
            foreach (array_values($tuple) as $i => myValue2) {
                $item[] = [myFields[$i] => myValue2];
            }
            $conditions['OR'][] = $item;
        }
        $surrogate.where($conditions, myTypeMap);

        $expression.setField($true);
        $expression.setValue($surrogate);
        $expression.setOperator('=');
    }
}
