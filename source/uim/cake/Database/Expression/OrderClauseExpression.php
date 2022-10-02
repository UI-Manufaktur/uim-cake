module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.Query;
import uim.cake.database.ValueBinder;
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
    this(myField, $direction)
    {
        this._field = myField;
        this._direction = strtolower($direction) === 'asc' ? 'ASC' : 'DESC';
    }

    /**
     * @inheritDoc
     */
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

    /**
     * @inheritDoc
     */
    function traverse(Closure $callback)
    {
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
