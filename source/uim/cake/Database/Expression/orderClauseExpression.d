module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * An expression object for complex ORDER BY clauses
 */
class OrderClauseExpression : IExpression, FieldInterface
{
    use FieldTrait;

    /**
     * The direction of sorting.
     *
     * @var string
     */
    protected $_direction;

    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|string myField The field to order on.
     * @param string $direction The direction to sort on.
     */
    this(myField, $direction) {
        this._field = myField;
        this._direction = strtolower($direction) === 'asc' ? 'ASC' : 'DESC';
    }


    function sql(ValueBinder $binder): string
    {
        /** @var \Cake\Database\IExpression|string myField */
        myField = this._field;
        if (myField instanceof Query) {
            myField = sprintf('(%s)', myField.sql($binder));
        } elseif (myField instanceof IExpression) {
            myField = myField.sql($binder);
        }

        return sprintf('%s %s', myField, this._direction);
    }


    function traverse(Closure $callback) {
        if (this._field instanceof IExpression) {
            $callback(this._field);
            this._field.traverse($callback);
        }

        return this;
    }

    /**
     * Create a deep clone of the order clause.
     *
     * @return void
     */
    auto __clone() {
        if (this._field instanceof IExpression) {
            this._field = clone this._field;
        }
    }
}
